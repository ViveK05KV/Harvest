import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-brand-mark',
  standalone: true,
  template: `
    <svg
      [attr.width]="size"
      [attr.height]="size * 1.25"
      viewBox="0 0 64 80"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <linearGradient id="brandMarkBody" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#ffc170" />
          <stop offset="60%" stop-color="#ef7d16" />
          <stop offset="100%" stop-color="#c85d06" />
        </linearGradient>
        <linearGradient id="brandMarkLeaf" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#8bc34a" />
          <stop offset="100%" stop-color="#4c8c2b" />
        </linearGradient>
      </defs>
      <path
        d="M32 21 C30 12 22 6 12 8 C14 16 22 22 32 21 Z"
        fill="url(#brandMarkLeaf)"
      />
      <path
        d="M32 21 C34 12 42 6 52 8 C50 16 42 22 32 21 Z"
        fill="url(#brandMarkLeaf)"
      />
      <path
        d="M32 24 C31.1 22 30.2 21 28 21 C17 21 8 33 8 47 C8 62 18 74 30 74 C31 74 31.8 74 33 74 C45 74 56 62 56 47 C56 33 47 21 36 21 C33.8 21 32.9 22 32 24 Z"
        fill="url(#brandMarkBody)"
      />
      <ellipse
        cx="20"
        cy="37"
        rx="4.5"
        ry="7"
        fill="#fff"
        opacity="0.45"
        transform="rotate(-25 20 37)"
      />
    </svg>
  `
})
export class BrandMarkComponent {
  @Input() size = 40;
}
