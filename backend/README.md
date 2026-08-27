# quizMoi local backend

This FastAPI service keeps the OpenAI key outside the Android application and validates generated quiz data before Flutter receives it.

It exposes two quiz-generation routes and one no-cost source-preview route:

- `POST /v1/quizzes/generate` accepts pasted source text as JSON.
- `POST /v1/quizzes/generate-pdf` accepts a PDF and generation settings as multipart form data.
- `POST /v1/sources/web/preview` retrieves and cleans one public web article without contacting OpenAI.

The PDF route validates a maximum 10 MB file and the PDF signature, then sends the document directly to the OpenAI Responses API as an `input_file` with low-detail page images. The request uses structured output and `store=false`; quizMoi stores only source metadata and generated learning data locally, not the PDF bytes. A scanned or protected PDF can still fail if the model cannot read enough useful content, and that failure is returned without losing the learner's selected source.

Both generation routes require a client-created `requestId`. If a mobile connection drops after FastAPI accepted the request, Flutter retries with the same ID. The backend reuses the in-progress operation or completed quiz instead of sending a second paid provider request. Completed results remain in memory for one hour, with at most 64 retained operations; restarting the backend clears this prototype recovery cache. The cache retains the generated quiz and an input fingerprint, not the original source text or PDF bytes.

The web-preview route accepts only public standard-port HTTP/HTTPS destinations, validates each redirect, rejects private/local addresses and unsupported content, limits the downloaded response to 2 MB, strips common non-article HTML, and returns at most 12,000 cleaned characters. Common paywall or sign-in responses receive a stable error category. The backend does not log article text, and OpenAI is not called until Flutter sends the learner-confirmed cleaned text through the normal generation route.

## Windows setup

From the project root:

```cmd
cd backend
py -3.11 -m venv .venv
.venv\Scripts\activate
python -m pip install -r requirements.txt
```

Set the key only in your local environment. Do not paste it into Dart, Python source, screenshots, chat, or Git:

```cmd
set OPENAI_API_KEY=your-key-here
set OPENAI_MODEL=gpt-5.6-luna
```

Start the service:

```cmd
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

The Android emulator reaches the host computer through `http://10.0.2.2:8000`. Only the Android debug manifest permits this local clear-text connection; release builds remain HTTPS-only.

Run backend tests:

```cmd
python -m pytest
```
