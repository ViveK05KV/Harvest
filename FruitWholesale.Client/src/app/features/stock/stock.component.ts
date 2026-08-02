import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { MatTableModule } from '@angular/material/table';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTooltipModule } from '@angular/material/tooltip';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialog } from '@angular/material/dialog';
import { StockService } from './stock.service';
import { StockAdjustmentFormComponent } from './stock-adjustment-form.component';
import { StockLedgerDialogComponent } from './stock-ledger-dialog.component';
import { CurrentStock } from '../../core/models/stock.model';
import { NotificationService } from '../../core/services/notification.service';
import { AuthService } from '../../core/services/auth.service';

const LOW_STOCK_THRESHOLD = 10;

@Component({
  selector: 'app-stock',
  standalone: true,
  imports: [MatTableModule, MatButtonModule, MatIconModule, MatTooltipModule, MatProgressBarModule, MatChipsModule],
  templateUrl: './stock.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class StockComponent implements OnInit {
  private readonly stockService = inject(StockService);
  private readonly dialog = inject(MatDialog);
  private readonly notification = inject(NotificationService);
  readonly authService = inject(AuthService);

  readonly displayedColumns = ['fruitName', 'currentStock', 'unit', 'boxes', 'actions'];
  readonly items = signal<CurrentStock[]>([]);
  readonly loading = signal(false);

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

  isLow(stock: CurrentStock): boolean {
    return stock.currentStock <= LOW_STOCK_THRESHOLD;
  }

  boxSummary(stock: CurrentStock): string {
    if (!stock.tracksByBox) return '';
    const opened = stock.openedBoxRemainingKg != null ? ` (+1 opened, ${stock.openedBoxRemainingKg.toFixed(1)}kg)` : '';
    return `${stock.fullBoxCount} box${stock.fullBoxCount === 1 ? '' : 'es'}${opened}`;
  }

  viewLedger(stock: CurrentStock): void {
    this.dialog.open(StockLedgerDialogComponent, {
      width: '700px',
      data: { fruitID: stock.fruitID, fruitName: stock.fruitName, unit: stock.unit }
    });
  }

  openAdjustment(): void {
    this.dialog
      .open(StockAdjustmentFormComponent, { width: '440px' })
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
}
