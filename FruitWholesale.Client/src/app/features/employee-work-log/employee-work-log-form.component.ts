import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { MatDialogModule, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatAutocompleteModule, MatAutocompleteSelectedEvent } from '@angular/material/autocomplete';
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
    MatAutocompleteModule,
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
    employeeSearch: this.fb.nonNullable.control<string>(''),
    jobType: [this.data?.jobType ?? 'Supply', Validators.required],
    routeID: this.fb.control<number | null>(this.data?.routeID ?? null),
    amount: [this.data?.amount ?? 0, [Validators.required, Validators.min(0)]],
    paymentMode: [this.data?.paymentMode ?? 'Cash', Validators.required],
    remarks: [this.data?.remarks ?? '']
  });

  private readonly jobType = toSignal(this.form.controls.jobType.valueChanges, { initialValue: this.form.controls.jobType.value });
  readonly showRoute = computed(() => ROUTE_RELEVANT_JOB_TYPES.includes(this.jobType()));

  ngOnInit(): void {
    this.employeeService.getAllActive().subscribe((employees) => {
      this.employees.set(employees);
      if (this.data?.employeeID) {
        this.form.controls.employeeSearch.setValue(this.employeeNameById(this.data.employeeID));
      }
    });
    this.routeService.getAllActive().subscribe((routes) => this.routes.set(routes));
  }

  employeeNameById(employeeID: number | null): string {
    return this.employees().find((e) => e.employeeID === employeeID)?.fullName ?? '';
  }

  readonly displayEmployee = (value: unknown): string =>
    typeof value === 'number' ? this.employeeNameById(value) : typeof value === 'string' ? value : '';

  filteredEmployees(search: string | null | undefined): Employee[] {
    const term = (search ?? '').trim().toLowerCase();
    if (!term) return this.employees();
    return this.employees().filter((e) => e.fullName.toLowerCase().includes(term));
  }

  // MatAutocomplete refocuses the trigger input right after an option is
  // clicked, which re-fires (focus) - skip that one synthetic refocus so it
  // can't immediately clear the name onEmployeeSelected just wrote.
  private employeeJustSelected = false;

  onEmployeeSelected(event: MatAutocompleteSelectedEvent): void {
    const employeeID = event.option.value as number;
    this.form.patchValue({ employeeID, employeeSearch: this.employeeNameById(employeeID) });
    this.employeeJustSelected = true;
  }

  onEmployeeSearchFocus(): void {
    if (this.employeeJustSelected) {
      this.employeeJustSelected = false;
      return;
    }
    if (this.form.controls.employeeSearch.value === this.employeeNameById(this.form.controls.employeeID.value)) {
      this.form.controls.employeeSearch.setValue('');
    }
  }

  // Typing away from the settled employee name must invalidate the stale employeeID -
  // otherwise the form stays "valid" with the old employee while the field shows
  // different text, and save() would silently post against the wrong employee.
  onEmployeeSearchInput(): void {
    this.form.controls.employeeID.setValue(null);
  }

  onEmployeeSearchBlur(): void {
    if (this.form.controls.employeeID.value === null) {
      this.form.controls.employeeSearch.setValue('');
    }
  }

  save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { employeeSearch, ...raw } = this.form.getRawValue();
    this.dialogRef.close({
      ...raw,
      workDate: toIso(raw.workDate as unknown as Date),
      routeID: this.showRoute() ? raw.routeID : null
    });
  }
}
