import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { debounceTime, distinctUntilChanged, Subject } from 'rxjs';
import { UserService } from './user.service';
import { UserFormComponent } from './user-form.component';
import { User } from '../../core/models/master-data.model';
import { PaginationRequest, USER_ROLES, UserRole } from '../../core/models/common.model';
import { NotificationService } from '../../core/services/notification.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-user-list',
  standalone: true,
  imports: [DatePipe, MatIconModule, MatProgressBarModule],
  templateUrl: './user-list.component.html',
  styleUrl: './user-list.component.scss'
})
export class UserListComponent implements OnInit {
  private readonly service = inject(UserService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  readonly authService = inject(AuthService);

  readonly items = signal<User[]>([]);
  readonly totalCount = signal(0);
  readonly loading = signal(false);

  readonly roles = USER_ROLES;
  readonly roleFilter = signal<UserRole | 'all'>('all');
  readonly searchTerm = signal('');

  readonly filteredItems = computed(() => {
    const role = this.roleFilter();
    return role === 'all' ? this.items() : this.items().filter((u) => u.role === role);
  });
  readonly adminCount = computed(() => this.filteredItems().filter((u) => u.role === 'Admin').length);

  protected readonly request: PaginationRequest = { pageNumber: 1, pageSize: 10, searchTerm: '' };
  private readonly searchSubject = new Subject<string>();

  constructor() {
    this.searchSubject.pipe(debounceTime(350), distinctUntilChanged()).subscribe((term) => {
      this.request.searchTerm = term;
      this.request.pageNumber = 1;
      this.load();
    });
  }

  ngOnInit(): void {
    this.load();
  }

  onSearch(term: string): void {
    this.searchTerm.set(term);
    this.searchSubject.next(term);
  }

  onRoleFilter(value: string): void {
    this.roleFilter.set((value as UserRole | 'all') || 'all');
  }

  clearFilters(): void {
    this.searchTerm.set('');
    this.roleFilter.set('all');
    this.request.searchTerm = '';
    this.request.pageNumber = 1;
    this.load();
  }

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No users';
    const start = (this.request.pageNumber - 1) * this.request.pageSize + 1;
    const end = Math.min(start + this.request.pageSize - 1, total);
    return `${start}–${end} of ${total}`;
  }

  prevPage(): void {
    if (this.request.pageNumber <= 1) return;
    this.request.pageNumber--;
    this.load();
  }

  nextPage(): void {
    if (this.request.pageNumber * this.request.pageSize >= this.totalCount()) return;
    this.request.pageNumber++;
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
        if (!confirmed) return;
        action$.subscribe({
          next: () => {
            this.notification.success('Status updated.');
            this.load();
          }
        });
      });
  }
}
