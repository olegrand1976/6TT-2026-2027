# node:24 (LTS) fournit npm 11, exempt du bug d'arborist de npm 10.x qui
# faisait echouer l'installation de Nuxt :
#   npm error Cannot read properties of null (reading 'edgesOut')
FROM node:24-alpine

WORKDIR /app

# Couche de cache des dependances : ne change que si package.json change.
# Pas de hook `postinstall` dans package.json : `nuxt prepare` a besoin de
# nuxt.config.ts, qui n'est copie qu'a l'etape suivante.
COPY package*.json ./
RUN npm install

COPY . .
RUN npm run prepare:nuxt

ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=development

EXPOSE 3000

CMD ["npm", "run", "dev"]
