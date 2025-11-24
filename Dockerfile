FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# 這裡改成 3000，因為你的程式碼是跑在 3000
EXPOSE 3000
CMD ["npm", "start"]