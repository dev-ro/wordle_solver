# **Optimized Architectural Plan: Multi-Language Wordle Solver**

This document outlines a revised architectural design for a scalable, cost-efficient, and multi-language Wordle Solver. It integrates a robust feedback mechanism for user-submitted words and general app improvements, and it incorporates key optimizations for performance, security, and operational management.

### **I. High-Level Architecture**

The system will use a client-server model. A Flutter client provides a responsive UI and manages the game state, while a Firebase backend, powered by Python Cloud Functions, handles all heavy computation.

graph TD  
    subgraph Client \[Flutter App \- Solver UI\]  
        UI\[Solver Interface\]  
        SM\[State Management (Riverpod/BLoC)\]  
        Repo\[Repository Layer\]  
    end

    subgraph Backend \[Firebase\]  
        CF\_PY\[Cloud Functions \- Python (Solver Engine)\]  
        Auth\[Firebase Authentication\]  
        DB\[Firestore Database\]  
        CS\[Cloud Storage \- Dictionaries\]  
    end

    subgraph Feedback & Ops  
        FeedbackUI\[Feedback/Missing Word Forms\]  
        ManualReview{Manual/Semi-Automated Review}  
        CICD\[CI/CD Pipeline (e.g., GitHub Actions)\]  
    end

    Client \-- API Calls \--\> Backend  
    Repo \-- HTTPS Callable \--\> CF\_PY  
    Repo \-- CRUD \--\> DB  
    Repo \-- Manages \--\> Auth

    CF\_PY \-- Optimized Read (Cached) \--\> CS  
      
    FeedbackUI \-- Write \--\> DB  
    DB \-- Triggers \--\> ManualReview  
    ManualReview \-- Updates \--\> CICD  
    CICD \-- Deploys to \--\> CS

### **II. Backend Architecture (Firebase & Python)**

The backend is designed to be stateless, scalable, and cost-efficient.

#### **1\. The Solver Engine (Cloud Functions \- Python)**

The core logic resides in a stateless Python Cloud Function.

* **calculateNextMove (HTTPS Callable Function):**  
  * **Input (JSON):** The client sends the full game state in a single request.  
    {  
      "config": {  
        "wordLength": 5,  
        "prefix": null,  
        "dictionary": "english\_words.json"   
      },  
      "history": \[  
        {"guess": "crane", "feedback": "bbbyg"},  
        {"guess": "sloth", "feedback": "bybbg"}  
      \]  
    }

  * **Logic:**  
    1. **Load Dictionary:** Load the specified dictionary from the in-memory cache (see Optimization below).  
    2. **Initialize:** Create an initial list of possible words based on wordLength and prefix.  
    3. **Iterative Filtering:** Loop through the history array, applying the filter\_possible\_words logic at each step to progressively narrow the list of candidates.  
    4. **Recommend:** Run scoring logic (recommend\_guesses) on the remaining words.  
    5. **Analyze Fillers:** Use find\_variable\_letter\_positions to suggest optimal filler words if the solution space is large or fragmented.  
  * **Output (JSON):** Return a structured response with recommendations, scores, and filler word analysis.  
* **Refactoring wordle.py for Serverless:**  
  * **Remove all I/O and CLI logic:** Eliminate input(), print(), and sys.argv parsing.  
  * **Ensure Statelessness:** Remove global state variables like guess\_count. All states must be passed as arguments to the core functions.  
  * **Pre-computation:** To optimize filtering speed, pre-process dictionaries upon loading to create a data structure that maps each word to its letter counts (e.g., {'apple': {'a':1, 'p':2, 'l':1, 'e':1}}). This avoids repeated word.count() calls inside the filter loop.

#### **2\. Performance and Cost Optimization**

* **In-Memory Caching with Cloud Storage (Primary Optimization):**  
  1. Store all dictionaries (e.g., english\_words.json, spanish\_words.json) as JSON files in a dedicated **Cloud Storage** bucket.  
  2. In the Python Cloud Function, use a **global variable** to act as an in-memory cache.  
  3. On a **cold start**, the function instance downloads the requested dictionary from Cloud Storage and populates the global variable.  
  4. On all subsequent **warm starts**, the function reuses the in-memory dictionary, resulting in near-instant data access and minimal cost.  
* **Cold Start Mitigation:**  
  * To ensure a consistently fast user experience, the calculateNextMove Cloud Function can be configured with a **minimum number of instances** (e.g., min\_instances \= 1). This keeps at least one instance warm and ready to serve requests, effectively eliminating cold start latency for most users at a predictable cost.

#### **3\. Dictionary and Feedback Management**

* **Operational Workflow (CI/CD):**  
  * Official dictionaries will be managed in a source control repository (e.g., GitHub).  
  * A **CI/CD pipeline** (e.g., GitHub Actions) will automatically deploy any changes (updates, new languages) from the repository to the Cloud Storage bucket, ensuring a controlled and versioned update process.  
* **User-Submitted Words and Feedback:**  
  * A top-level Firestore collection named feedback will be created. It will be open for writes by any authenticated user.  
  * **feedback/missingWords (Subcollection):** When a user submits a missing word, a new document is created here.  
    // Document in feedback/missingWords  
    {  
      "word": "slang",  
      "dictionary": "english\_words.json",  
      "submittedAt": "2025-08-07T16:00:00Z",  
      "userId": "some-anonymous-or-real-uid"  
    }

  * **feedback/appImprovements (Subcollection):** For general suggestions.  
    // Document in feedback/appImprovements  
    {  
      "comment": "It would be cool to have a stats page\!",  
      "submittedAt": "2025-08-07T16:05:00Z",  
      "userId": "some-anonymous-or-real-uid"  
    }

  * **Integration Process:** A periodic, semi-automated process (e.g., a weekly script or manual review) will collate submissions from missingWords, validate them in good faith, and add them to the official dictionary files in the source repository, triggering the CI/CD update pipeline.

### **III. Frontend Architecture (Flutter)**

The UI will be clean, responsive, and optimized for the task of solving.

* **Architecture:** Use **Clean Architecture** with a dedicated Repository layer to separate UI from business logic. **Riverpod** or **BLoC** is recommended for state management.  
* **UI/UX Design:**  
  * **Dynamic Input Grid:** The central grid will dynamically adjust to the wordLength specified by the user.  
  * **Tap-to-Color Feedback:** Users will tap tiles to cycle through feedback states (Gray → Yellow → Green), which is much faster than typing.  
  * **Recommendations Panel:** Clearly display top recommendations and remaining word count. Tapping a word will auto-fill it into the next guess row.  
  * **Feedback Forms:** Simple, dedicated forms in the app's settings for submitting missing words and general feedback.  
  * **Responsiveness:** Use clear loading indicators while awaiting the Cloud Function response.

### **IV. Security and API Contract**

A robust security model and a clear API contract are essential.

#### **1\. Security Rules**

* **Firestore Rules:**  
  rules\_version \= '2';  
  service cloud.firestore {  
    match /databases/{database}/documents {  
      // Users can only access their own data  
      match /users/{userId}/{document=\*\*} {  
        allow read, write: if request.auth \!= null && request.auth.uid \== userId;  
      }

      // Any authenticated user can submit feedback  
      match /feedback/{document=\*\*} {  
        allow create: if request.auth \!= null;  
      }  
    }  
  }

* **Cloud Storage Rules:**  
  * Dictionary files will be configured to be readable **only by the Cloud Function's service account**, not publicly. This prevents unauthorized access or scraping of the dictionaries.

#### **2\. API Error Handling (calculateNextMove)**

The function will return standardized error responses to be handled gracefully by the client.

| Status Code | Error Code (Internal) | Message | Client Action |
| :---- | :---- | :---- | :---- |
| 400 Bad Request | INVALID\_ARGUMENT | Malformed request body or invalid parameters. | Show a generic error message: "An unexpected error occurred." |
| 400 Bad Request | DICTIONARY\_NOT\_FOUND | The requested dictionary file does not exist. | Show a specific error: "Dictionary not found. Please select another." |
| 401 Unauthorized | UNAUTHENTICATED | User is not authenticated. | Should not happen with anonymous auth, but useful for debugging. |
| 500 Internal Server Error | INTERNAL\_ERROR | An unhandled exception occurred in the solver logic. | Show a generic error message and prompt user to try again. |

### **V. Authentication**

* **Strategy:** Use **Firebase Anonymous Authentication** by default for a frictionless user experience.  
* **Account Linking:** Allow users to optionally link their anonymous account to a permanent provider (e.g., Google, Apple) to sync their history and preferences across devices.