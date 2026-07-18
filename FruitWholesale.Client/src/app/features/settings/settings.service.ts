import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { CashAdjustment, CompanySettings, SaveCompanySettings } from '../../core/models/master-data.model';

@Injectable({ providedIn: 'root' })
export class SettingsService {
  private readonly baseUrl = `${environment.apiUrl}/companysettings`;

  constructor(private readonly http: HttpClient) {}

  get(): Observable<CompanySettings> {
    return this.http.get<CompanySettings>(this.baseUrl);
  }

  save(dto: SaveCompanySettings): Observable<CompanySettings> {
    return this.http.put<CompanySettings>(this.baseUrl, dto);
  }

  applyCashAdjustment(dto: CashAdjustment): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/cash-adjustment`, dto);
  }

  uploadLogo(file: File): Observable<CompanySettings> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<CompanySettings>(`${this.baseUrl}/logo`, formData);
  }
}
