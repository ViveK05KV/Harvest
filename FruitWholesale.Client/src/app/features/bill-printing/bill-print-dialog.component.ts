import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { forkJoin } from 'rxjs';
import { SupplyService } from '../supply/supply.service';
import { ShopMasterService } from '../shop-master/shop-master.service';
import { BrandingService } from '../../core/services/branding.service';
import { Supply, SupplyBillExtras } from '../../core/models/transactions.model';

export interface BillPrintDialogData {
  supplyId: number;
}

@Component({
  selector: 'app-bill-print-dialog',
  standalone: true,
  imports: [
    DatePipe,
    DecimalPipe,
    FormsModule,
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressBarModule
  ],
  templateUrl: './bill-print-dialog.component.html',
  styleUrl: './bill-print-dialog.component.scss'
})
export class BillPrintDialogComponent implements OnInit {
  private readonly supplyService = inject(SupplyService);
  private readonly shopService = inject(ShopMasterService);
  readonly branding = inject(BrandingService);
  readonly data = inject<BillPrintDialogData>(MAT_DIALOG_DATA);

  readonly loading = signal(true);
  readonly supply = signal<Supply | null>(null);
  readonly shopPhone = signal<string | undefined>(undefined);
  readonly shopAddress = signal<string | undefined>(undefined);
  readonly oldBalance = signal(0);
  readonly cashReceived = signal(0);

  readonly netBalance = computed(() => this.oldBalance() + (this.supply()?.totalAmount ?? 0) - this.cashReceived());

  ngOnInit(): void {
    forkJoin({
      supply: this.supplyService.getById(this.data.supplyId),
      extras: this.supplyService.getBillExtras(this.data.supplyId)
    }).subscribe(({ supply, extras }: { supply: Supply; extras: SupplyBillExtras }) => {
      this.supply.set(supply);
      this.oldBalance.set(extras.oldBalance);
      this.cashReceived.set(extras.suggestedCashReceived);
      this.shopService.getById(supply.shopID).subscribe((shop) => {
        this.shopPhone.set(shop.phone);
        this.shopAddress.set(shop.address);
        this.loading.set(false);
      });
    });
  }

  onCashReceivedChange(value: number): void {
    this.cashReceived.set(value || 0);
  }

  print(): void {
    window.print();
  }
}
