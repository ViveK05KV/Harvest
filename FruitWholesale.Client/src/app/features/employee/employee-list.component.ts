import { Component, inject } from '@angular/core';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule } from '@angular/material/paginator';
import { MatSortModule } from '@angular/material/sort';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MasterListBase } from '../../core/base/master-list-base';
import { EmployeeService } from './employee.service';
import { EmployeeFormComponent } from './employee-form.component';
import { Employee, SaveEmployee } from '../../core/models/master-data.model';

@Component({
  selector: 'app-employee-list',
  standalone: true,
  imports: [
    MatTableModule,
    MatPaginatorModule,
    MatSortModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    MatTooltipModule,
    MatProgressBarModule
  ],
  templateUrl: './employee-list.component.html'
})
export class EmployeeListComponent extends MasterListBase<Employee, SaveEmployee> {
  readonly displayedColumns = ['fullName', 'phone', 'address', 'isActive', 'actions'];

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

  openCreate(): void {
    this.openFormDialog(EmployeeFormComponent, '480px', null);
  }

  openEdit(employee: Employee): void {
    this.openFormDialog(EmployeeFormComponent, '480px', employee);
  }
}
