import { HttpClient } from '@angular/common/http';
import { Injectable, computed, signal } from '@angular/core';
import { catchError, of } from 'rxjs';
import { environment } from '../../../environments/environment';
import { CompanySettings } from '../models/master-data.model';

@Injectable({ providedIn: 'root' })
export class BrandingService {
  private readonly baseUrl = `${environment.apiUrl}/companysettings`;

  readonly companySettings = signal<CompanySettings | null>(null);
  readonly companyName = computed(() => this.companySettings()?.companyName ?? 'Fruit Wholesale');
  readonly logoUrl = computed(() => {
    const logoUrl = this.companySettings()?.logoUrl;
    return logoUrl ? `${environment.serverUrl}${logoUrl}` : null;
  });

  constructor(private readonly http: HttpClient) {}

  refresh(): void {
    this.http
      .get<CompanySettings>(this.baseUrl)
      .pipe(catchError(() => of(null)))
      .subscribe((settings) => this.companySettings.set(settings));
  }
}
