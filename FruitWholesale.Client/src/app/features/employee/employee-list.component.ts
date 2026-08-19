import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { Sort } from '@angular/material/sort';
import { MasterListBase } from '../../core/base/master-list-base';
import { EmployeeService } from './employee.service';
import { EmployeeFormComponent } from './employee-form.component';
import { Employee, SaveEmployee } from '../../core/models/master-data.model';

@Component({
  selector: 'app-employee-list',
  standalone: true,
  imports: [MatIconModule, MatProgressBarModule],
  templateUrl: './employee-list.component.html',
  styleUrl: './employee-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EmployeeListComponent extends MasterListBase<Employee, SaveEmployee> {
  readonly sortDirection = signal<'asc' | 'desc' | ''>('');

  constructor() {
    super(inject(EmployeeService), {
      idOf: (e) => e.employeeID,
      nameOf: (e) => e.fullName,
      isActiveOf: (e) => e.isActive,
      entityLabel: 'Employee',
      createdMessage: 'Employee added successfully.',
      updatedMessage: 'Employee updated successfully.'
    });
  }

  rangeLabel(): string {
    const total = this.totalCount();
    if (total === 0) return 'No employees';
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

  toggleSort(): void {
    const next = this.sortDirection() === 'asc' ? 'desc' : this.sortDirection() === 'desc' ? '' : 'asc';
    this.sortDirection.set(next);
    this.onSort({ active: 'fullName', direction: next } as Sort);
  }

  openCreate(): void {
    this.openFormDialog(EmployeeFormComponent, '480px', null);
  }

  openEdit(employee: Employee): void {
    this.openFormDialog(EmployeeFormComponent, '480px', employee);
  }
}
