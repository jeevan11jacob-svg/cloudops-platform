const request = require("supertest");
const app = require("./server");

describe("CloudOps Backend API", () => {
  test("GET /api/health should return healthy status", async () => {
    const response = await request(app).get("/api/health");

    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe("healthy");
    expect(response.body.service).toBe("cloudops-backend");
  });
});
