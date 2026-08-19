import { HttpClient } from '@angular/common/http';
import { Injectable, computed, signal } from '@angular/core';
import { Observable, catchError, of, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { CompanySettings } from '../models/master-data.model';

@Injectable({ providedIn: 'root' })
export class BrandingService {
  private readonly baseUrl = `${environment.apiUrl}/companysettings`;

  readonly companySettings = signal<CompanySettings | null>(null);
  readonly companyName = computed(() => this.companySettings()?.companyName ?? 'Harvest');
  readonly logoUrl = computed(() => {
    const logoUrl = this.companySettings()?.logoUrl;
    if (!logoUrl) return null;
    // Logos are stored as base64 data URIs (see CompanySettingsController.UploadLogo) since the
    // API's container filesystem is ephemeral. Older records may still have a relative file path.
    return logoUrl.startsWith('data:') ? logoUrl : `${environment.serverUrl}${logoUrl}`;
  });

  constructor(private readonly http: HttpClient) {}

  refresh(): void {
    this.http
      .get<CompanySettings>(this.baseUrl)
      .pipe(catchError(() => of(null)))
      .subscribe((settings) => this.companySettings.set(settings));
  }

  // Used by route guards that need the setting before the layout's own
  // refresh() (a constructor side effect) has necessarily run yet.
  ensureLoaded(): Observable<CompanySettings | null> {
    const current = this.companySettings();
    if (current) return of(current);

    return this.http.get<CompanySettings>(this.baseUrl).pipe(
      tap((settings) => this.companySettings.set(settings)),
      catchError(() => of(null))
    );
  }
}
