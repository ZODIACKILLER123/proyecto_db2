import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// El navegador llama a /api/...; Vite lo reenvia al backend (sin CORS).
const target = process.env.API_PROXY_TARGET || 'http://localhost:8000'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    watch: { usePolling: true }, // necesario para recargar en Docker (Windows/Mac)
    proxy: {
      '/api': { target, changeOrigin: true, rewrite: (p) => p.replace(/^\/api/, '') },
    },
  },
})
