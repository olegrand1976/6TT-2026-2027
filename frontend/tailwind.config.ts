import type { Config } from 'tailwindcss'

export default <Partial<Config>>{
  theme: {
    extend: {
      colors: {
        asphalt: {
          900: '#0b0e14',
          800: '#131824',
          700: '#1c2333',
          600: '#2a3348',
        },
        neon: '#4ade80',
      },
      fontFamily: {
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
    },
  },
}
