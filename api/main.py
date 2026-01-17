from fastapi import FastAPI

app = FastAPI(title="OmniUtil API")

@app.get("/")
def root():
    return {"status": "OmniUtil API online"}
