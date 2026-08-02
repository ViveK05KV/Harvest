import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { MatDatepickerModule } from '@angular/material/datepicker';
import { MatNativeDateModule } from '@angular/material/core';
import { EmployeeService } from '../employee/employee.service';
import { RouteMasterService } from '../route-master/route-master.service';
import { Employee, EmployeeWorkLog, RouteMaster } from '../../core/models/master-data.model';
import { JOB_TYPES, PAYMENT_MODES } from '../../core/models/common.model';
import { toIso } from '../../core/utils/date.util';

const ROUTE_RELEVANT_JOB_TYPES = ['Supply', 'Collection'];

@Component({
  selector: 'app-employee-work-log-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatDatepickerModule,
    MatNativeDateModule
  ],
  templateUrl: './employee-work-log-form.component.html'
})
export class EmployeeWorkLogFormComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly employeeService = inject(EmployeeService);
  private readonly routeService = inject(RouteMasterService);
  readonly dialogRef = inject(MatDialogRef<EmployeeWorkLogFormComponent>);
  readonly data = inject<EmployeeWorkLog | null>(MAT_DIALOG_DATA);

  readonly jobTypes = JOB_TYPES;
  readonly paymentModes = PAYMENT_MODES;
  readonly employees = signal<Employee[]>([]);
  readonly routes = signal<RouteMaster[]>([]);

  readonly form = this.fb.nonNullable.group({
    workDate: [this.data ? new Date(this.data.workDate) : new Date(), Validators.required],
    employeeID: this.fb.control<number | null>(this.data?.employeeID ?? null, Validators.required),
    jobType: [this.data?.jobType ?? 'Supply', Validators.required],
    routeID: this.fb.control<number | null>(this.data?.routeID ?? null),
    amount: [this.data?.amount ?? 0, [Validators.required, Validators.min(0)]],
    paymentMode: [this.data?.paymentMode ?? 'Cash', Validators.required],
    remarks: [this.data?.remarks ?? '']
  });

  private readonly jobType = toSignal(this.form.controls.jobType.valueChanges, { initialValue: this.form.controls.jobType.value });
  readonly showRoute = computed(() => ROUTE_RELEVANT_JOB_TYPES.includes(this.jobType()));

  ngOnInit(): void {
    this.employeeService.getAllActive().subscribe((employees) => this.employees.set(employees));
    this.routeService.getAllActive().subscribe((routes) => this.routes.set(routes));
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const raw = this.form.getRawValue();
    this.dialogRef.close({
      ...raw,
      workDate: toIso(raw.workDate as unknown as Date),
      routeID: this.showRoute() ? raw.routeID : null
    });
  }
}
