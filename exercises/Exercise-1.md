# Exercise 1 — Intelligent Document Processing (IDP)

> **Goal:** replace the two placeholder IDP service tasks with real **Document Classification** and **Document Extraction** templates powered by OpenAI. Read three uploaded PDFs, classify them, extract the structured fields, and feed them into the DMN validation step.

---

## What you will learn

- The Camunda 8.9 IDP capability split: *classification templates* vs *extraction templates*.
- How to wire the OpenAI Compatible provider so IDP runs against OpenAI directly.
- How to publish an IDP template as a connector and apply it to a BPMN service task.
- How to feed the structured extraction output into a downstream DMN decision (already shipped: `document-validity.dmn`).
- How extraction confidence and the fallback "unclassified-document" value give you deterministic gateway routing.

## Prerequisites

1. Exercise 1 complete — workers are running.
2. A Camunda 8 SaaS cluster with cluster version ≥ **8.9.x** (classification requires this).
3. An OpenAI API key with chat-completions access (model used: `gpt-4.5-mini`).
4. The cluster's **Connector secrets** configured (see Step 1).

---

## Step 1 — Register the OpenAI secrets in SaaS

1. Open the **Console** for your SaaS cluster.
2. Navigate to **Manage cluster ▸ Connector secrets**.
3. Add the following secrets:

   | Secret name                       | Value                                                  | Value with Camunda LLM.                              |
   |-----------------------------------|--------------------------------------------------------|------------------------------------------------------|
   | `OPENAI_API_KEY`                  | your OpenAI key (`sk-...`)                             | value from secret `CAMUNDA_PROVIDED_LLM_API_KEY`     |
   | `IDP_OPENAI_COMPATIBLE_ENDPOINT`  | `https://api.openai.com/v1`                            | value from secret `CAMUNDA_PROVIDED_LLM_API_ENDPOINT`|
   | `IDP_OPENAI_COMPATIBLE_HEADERS`   | `{"Authorization": "Bearer OPENAI_API_KEY"}`        | `{"Authorization": "Bearer OPENAI_API_KEY"}`            |

   > **Why a separate `IDP_OPENAI_COMPATIBLE_HEADERS`?** The IDP OpenAI Compatible provider expects authentication via headers, not a top-level API key. The connector substitutes `${OPENAI_API_KEY}` from the secret store at runtime.



## Step 2 — Create an IDP application

1. In Web Modeler, click **Create new ▸ IDP application**.
2. Name it `office-alpaca-idp` and select your cluster.
3. The IDP application becomes a folder where classification and extraction templates live.

## Step 3 — Build the classification template

1. Inside the IDP application click **Create new ▸ Classification template**.
2. Fill in:
   - **Name:** `Alpaca document classifier`
   - **Description:** Classifies the 3 supporting documents for an alpaca request.
   - **Provider:** OpenAI Compatible.
3. Click **Create**.
4. Define the explicit document types (don't use auto-classification — we want predictable routing):

   | Type id                          | Display name                | Classification Prompt                                              |
   |----------------------------------|-----------------------------|----------------------------------------------------------|
   | `alpaca-suitability`            | Alpaca Suitability          | Has "OFFICE ALPACA SUITABILITY FORM " in the headline.|
   | `alpaca-business-justification-memo`    | Alpaca Business Justification Memo | Contains "BUSINESS JUSTIFICATION MEMO" in the headline.   |

   Leave the default **fallback output value** of `unclassified-document` — the DMN in `document-validity.dmn` already routes that to *Request missing information*.

5. In the **Configure model** tab choose:
   - Model: `gpt-5.4-mini`  (enter the name and hit ENTER).
     - for Camunda provided LLM use `openai.gpt-oss-20b` (enter the name and hit ENTER)
6. **Test** the template with the sample files we ship in `office-alpaca-app/sample-documents/`. 
7. Click **Publish => to Project** — this makes the template available as a connector element template.

## Step 4 — Build the Alpaca Suitability extraction template

1. Click **Create new ▸ Extraction template** inside the same IDP application.
2. Fill in:
   - **Name:** `Alpaca Suitability Extraction`
   - **Provider:** OpenAI Compatible
   - **Extraction method:** Unstructured (the documents are free-form PDFs).
3. Define the extraction fields:

   | Field name              | Type    | Description                                      |
   |-------------------------|---------|--------------------------------------------------|
   | `officeLocation`        | string  | the office location preferred for the visit.     |
   | `vaccinationValidUntil` | string  | the vaccination valid until date                 |
   | `temperamentScore`      | number  | the temperament score                            |
   | `alpacaName`            | string  | the name of the Alpaca                           |
   | `visitDate`             | string  | the planned visit date                           |
   | `vaccinationStatus`     | string  | the vaccination status	                        |

4. **Test** the template against your sample PDFs and confirm that all fields populate.
5. **Publish to your project**.

## Step 5 — Build the Business Justification Memo extraction template

1. Click **Create new ▸ Extraction template** inside the same IDP application.
2. Fill in:
   - **Name:** `Business Justification Memo Extraction`
   - **Provider:** OpenAI Compatible
   - **Extraction method:** Unstructured (the documents are free-form PDFs).
3. Define the extraction fields:

   | Field name              | Type    | Description                                               |
   |-------------------------|---------|-----------------------------------------------------------|
   | `expectedBusinessValue` | string  | the expected business value.                              |
   | `requestedBudget`       | string  | the estimated overall budget as number (without currency) |


4. **Test** the template against your sample PDFs and confirm that all fields populate.
5. **Publish to your project**.

## Step 6 — Apply the templates to the BPMN

1. Open `Extract Alpaca Data` in Web Modeler.
2. Click **Classify uploaded documents** ▸ **Element template** ▸ select `Alpaca document classifier`.
3. Configure:
   - **Documents input** (`documents`): `=document` — the array of uploaded file references.
   - **Result variable**: `classificationResult`.
4. Repeat for **Extract Business Justification and Extract Alpaca suitability Info** with the according extraction templates:
   - **Documents input**: `=document`
   - **Result expression**: `={extractedFields: extractedFields}`.
5. Save and re-deploy from Modeler.

## Acceptance criteria

- [ ] Both classification and extraction templates are published.
- [ ] The BPMN tasks display the IDP template names (not the placeholder task types) in Modeler.
- [ ] A real Tasklist upload of the sample PDFs runs end-to-end to `Check Office Readiness`.
- [ ] At least one negative scenario routes the process to *Request missing information*.

## Reference links

- [IDP overview](https://docs.camunda.io/docs/components/modeler/web-modeler/idp/)
- [IDP document classification](https://docs.camunda.io/docs/components/modeler/web-modeler/idp/idp-document-classification/)
- [IDP document extraction](https://docs.camunda.io/docs/components/modeler/web-modeler/idp/idp-document-extraction/)
- [IDP OpenAI Compatible provider](https://docs.camunda.io/docs/components/modeler/web-modeler/idp/idp-configuration/#openai-compatible-provider)
- [IDP integrate into processes](https://docs.camunda.io/docs/components/modeler/web-modeler/idp/idp-integrate/)
- [Document handling](https://docs.camunda.io/docs/components/concepts/document-handling/)
