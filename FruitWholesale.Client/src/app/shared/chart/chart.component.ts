import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnDestroy, SimpleChanges, ViewChild } from '@angular/core';
import {
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  Chart,
  ChartConfiguration,
  ChartType,
  DoughnutController,
  Filler,
  Legend,
  LineController,
  LineElement,
  LinearScale,
  PointElement,
  Tooltip
} from 'chart.js';

// Only registering what dashboard.component.html actually renders (line, bar,
// doughnut) instead of Chart.register(...registerables), which pulls in
// every controller/plugin.
Chart.register(
  LineController,
  BarController,
  DoughnutController,
  LineElement,
  BarElement,
  PointElement,
  ArcElement,
  CategoryScale,
  LinearScale,
  Legend,
  Tooltip,
  Filler
);

@Component({
  selector: 'app-chart',
  standalone: true,
  template: `<canvas #canvas></canvas>`,
  styles: [`
    :host { display: block; position: relative; height: 100%; width: 100%; min-width: 0; }
    canvas { max-width: 100%; }
  `]
})
export class ChartComponent implements AfterViewInit, OnChanges, OnDestroy {
  @Input({ required: true }) type!: ChartType;
  @Input({ required: true }) data!: ChartConfiguration['data'];
  @Input() options: ChartConfiguration['options'] = {};

  @ViewChild('canvas') private readonly canvasRef!: ElementRef<HTMLCanvasElement>;
  private chart?: Chart;

  ngAfterViewInit(): void {
    this.render();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (this.chart && (changes['data'] || changes['options'])) {
      this.chart.data = this.data;
      this.chart.options = { ...this.chart.options, ...this.options };
      this.chart.update();
    }
  }

  ngOnDestroy(): void {
    this.chart?.destroy();
  }

  private render(): void {
    this.chart = new Chart(this.canvasRef.nativeElement, {
      type: this.type,
      data: this.data,
      options: { responsive: true, maintainAspectRatio: false, ...this.options }
    });
  }
}
