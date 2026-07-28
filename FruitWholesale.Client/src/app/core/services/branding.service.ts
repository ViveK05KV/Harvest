import { HttpClient } from '@angular/common/http';
import { Injectable, computed, signal } from '@angular/core';
import { catchError, of } from 'rxjs';
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
}
