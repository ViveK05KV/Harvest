import { Component, OnInit, ViewChild, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { MatTableModule } from '@angular/material/table';
import { MatPaginator, MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { UserService } from './user.service';
import { UserFormComponent } from './user-form.component';
import { User } from '../../core/models/master-data.model';
import { PaginationRequest } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-user-list',
  standalone: true,
  imports: [
    DatePipe,
    MatTableModule,
    MatPaginatorModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatTooltipModule,
    MatProgressBarModule,
    MatChipsModule
  ],
  templateUrl: './user-list.component.html'
})
export class UserListComponent implements OnInit {
  private readonly service = inject(UserService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  readonly authService = inject(AuthService);

  @ViewChild(MatPaginator) paginator!: MatPaginator;

  readonly displayedColumns = ['fullName', 'username', 'role', 'createdAt', 'isActive', 'actions'];
  readonly items = signal<User[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  private readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10, searchTerm: '' };
  private readonly searchSubject = new Subject<string>();

  constructor() {
    this.searchSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((term) => {
      this.request.searchTerm = term;
      this.request.pageNumber = 1;
      this.paginator.firstPage();
      this.load();
    });
  }

  ngOnInit(): void {
    this.load();
  }

  onSearch(term: string): void {
    this.searchSubject.next(term);
  }

  onPage(event: PageEvent): void {
    this.request.pageNumber = event.pageIndex + 1;
    this.request.pageSize = event.pageSize;
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.getPaged(this.request).subscribe({
      next: (result) => {
        this.items.set(result.items);
        this.totalCount.set(result.totalCount);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  openCreate(): void {
    this.dialog
      .open(UserFormComponent, { width: '450px', data: null })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.create(result).subscribe({
          next: () => {
            this.notification.success('User created successfully.');
            this.load();
          }
        });
      });
  }

  openEdit(user: User): void {
    this.dialog
      .open(UserFormComponent, { width: '450px', data: user })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.service.update(user.userID, result).subscribe({
          next: () => {
            this.notification.success('User updated successfully.');
            this.load();
          }
        });
      });
  }

  toggleActive(user: User): void {
    if (user.userID === this.authService.currentUser()?.userId) {
      this.notification.error('You cannot deactivate your own account.');
      this.load();
      return;
    }

    const action$ = user.isActive ? this.service.deactivate(user.userID) : this.service.activate(user.userID);
    this.confirmDialog
      .confirm({
        title: user.isActive ? 'Deactivate User' : 'Activate User',
        message: `Are you sure you want to ${user.isActive ? 'deactivate' : 'activate'} "${user.fullName}"?`,
        destructive: user.isActive
      })
      .subscribe((confirmed) => {
        if (!confirmed) {
          this.load();
          return;
        }
        action$.subscribe({
          next: () => {
            this.notification.success('Status updated.');
            this.load();
          }
        });
      });
  }
}
