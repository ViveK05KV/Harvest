import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { EmployeeLoanHistoryRow, EmployeeLoanRepayment, EmployeeLoanSummaryRow, SaveEmployeeLoanRepayment } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class EmployeeLoanService {
  private readonly baseUrl = `${environment.apiUrl}/employeeloan`;

  constructor(private readonly http: HttpClient) {}

  getSummary(): Observable<EmployeeLoanSummaryRow[]> {
    return this.http.get<EmployeeLoanSummaryRow[]>(`${this.baseUrl}/summary`);
  }

  getHistory(employeeId: number): Observable<EmployeeLoanHistoryRow[]> {
    return this.http.get<EmployeeLoanHistoryRow[]>(`${this.baseUrl}/${employeeId}/history`);
  }

  createRepayment(dto: SaveEmployeeLoanRepayment): Observable<EmployeeLoanRepayment> {
    return this.http.post<EmployeeLoanRepayment>(`${this.baseUrl}/repayments`, dto);
  }

  updateRepayment(id: number, dto: SaveEmployeeLoanRepayment): Observable<EmployeeLoanRepayment> {
    return this.http.put<EmployeeLoanRepayment>(`${this.baseUrl}/repayments/${id}`, dto);
  }

  deleteRepayment(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/repayments/${id}`);
  }
}
