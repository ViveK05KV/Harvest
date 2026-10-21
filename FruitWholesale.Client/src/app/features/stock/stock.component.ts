import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatDialog } from '@angular/material/dialog';
import { HttpErrorResponse } from '@angular/common/http';
import { StockService } from './stock.service';
import { StockAdjustmentFormComponent } from './stock-adjustment-form.component';
import { StockLedgerDialogComponent } from './stock-ledger-dialog.component';
import { StockItemEditComponent, StockItemEditResult } from './stock-item-edit.component';
import { CurrentStock } from '../../core/models/stock.model';
import { NotificationService } from '../../core/services/notification.service';
import { AuthService } from '../../core/services/auth.service';
import { ConfirmDialogService } from '../../shared/confirm-dialog/confirm-dialog.service';

const LOW_STOCK_THRESHOLD = 10;

@Component({
  selector: 'app-stock',
  standalone: true,
  imports: [MatIconModule, MatProgressBarModule],
  templateUrl: './stock.component.html',
  styleUrl: './stock.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class StockComponent implements OnInit {
  private readonly stockService = inject(StockService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  private readonly confirmDialog = inject(ConfirmDialogService);
  readonly authService = inject(AuthService);

  readonly items = signal<CurrentStock[]>([]);
  readonly loading = signal(false);
  readonly sortDirection = signal<'asc' | 'desc' | ''>('');
  readonly zeroingFruitID = signal<number | null>(null);

  readonly sortedItems = computed(() => {
    const direction = this.sortDirection();
    const items = this.items();
    if (!direction) return items;
    const factor = direction === 'asc' ? 1 : -1;
    return [...items].sort((a, b) => (a.currentStock - b.currentStock) * factor);
  });

  readonly canAdjust = this.authService.hasRole('Admin', 'Manager');

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.stockService.getCurrentStock().subscribe({
      next: (result) => {
        this.items.set(result);
        this.loading.set(false);
      },
      error: () => this.loading.set(false)
    });
  }

  toggleSort(): void {
    this.sortDirection.update((d) => (d === '' ? 'asc' : d === 'asc' ? 'desc' : ''));
  }

  isLow(stock: CurrentStock): boolean {
    return stock.currentStock <= LOW_STOCK_THRESHOLD;
  }

  hasInventory(stock: CurrentStock): boolean {
    return stock.currentStock !== 0 || stock.fullBoxCount > 0 || stock.openedBoxRemainingKg != null;
  }

  setStockToZero(stock: CurrentStock): void {
    this.confirmDialog.confirm({
      title: 'Set inventory to zero',
      message: `Set ${stock.fruitName} stock to zero? This clears its loose stock, full boxes, and opened-box quantity.`,
      confirmLabel: 'Set to 0',
      destructive: true
    }).subscribe((confirmed) => {
      if (!confirmed) return;
      this.zeroingFruitID.set(stock.fruitID);
      this.stockService.setStockToZero(stock.fruitID).subscribe({
        next: () => {
          this.zeroingFruitID.set(null);
          this.notification.success(`${stock.fruitName} stock set to zero.`);
          this.load();
        },
        error: (error: HttpErrorResponse) => {
          this.zeroingFruitID.set(null);
          const detail = Array.isArray(error.error?.errors)
            ? error.error.errors.join(' ')
            : typeof error.error?.message === 'string'
              ? error.error.message
              : '';
          this.notification.error(detail || `Could not set ${stock.fruitName} stock to zero (HTTP ${error.status || 'network error'}).`);
        }
      });
    });
  }

  boxSummary(stock: CurrentStock): string {
    if (!stock.tracksByBox) return '';
    const opened = stock.openedBoxRemainingKg != null ? ` (+1 opened, ${stock.openedBoxRemainingKg.toFixed(1)}kg)` : '';
    return `${stock.fullBoxCount} box${stock.fullBoxCount === 1 ? '' : 'es'}${opened}`;
  }

  viewLedger(stock: CurrentStock): void {
    this.dialog.open(StockLedgerDialogComponent, {
      width: '700px',
      // StockLedger quantities are always tracked in kg, even for a fruit whose
      // display/sale Unit is "Box" - a box purchase gets converted to its kg
      // equivalent before it's ever written to the ledger, so "Box" is never
      // the right unit to show next to a ledger In/Out/Balance figure.
      data: { fruitID: stock.fruitID, fruitName: stock.fruitName, unit: stock.tracksByBox ? 'kg' : stock.unit }
    });
  }

  openAdjustment(): void {
    this.dialog
      .open(StockAdjustmentFormComponent, { width: '480px', maxWidth: '95vw', autoFocus: 'dialog' })
      .afterClosed()
      .subscribe((result) => {
        if (!result) return;
        this.stockService.applyAdjustment(result).subscribe({
          next: () => {
            this.notification.success('Stock adjustment applied.');
            this.load();
          }
        });
      });
  }

  editItem(stock: CurrentStock): void {
    this.dialog
      .open(StockItemEditComponent, {
        width: '480px',
        maxWidth: '95vw',
        autoFocus: 'dialog',
        data: stock
      })
      .afterClosed()
      .subscribe((result: StockItemEditResult | undefined) => {
        if (!result) return;
        const difference = result.targetStock - stock.currentStock;
        if (difference === 0) return;
        this.stockService.applyAdjustment({
          fruitID: stock.fruitID,
          quantity: Math.abs(difference),
          isIncrease: difference > 0,
          narration: result.narration
        }).subscribe({
          next: () => {
            this.notification.success(`${stock.fruitName} inventory updated.`);
            this.load();
          }
        });
      });
  }
}
