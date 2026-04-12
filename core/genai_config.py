from __future__ import annotations

import os

from google import genai


def _truthy(val: str | None) -> bool:
    return val is not None and val.strip().lower() in ("1", "true", "yes", "on")


def build_genai_client() -> genai.Client:
    """
    Gemini Developer API: set API_KEY (default).

    Vertex AI: set GOOGLE_GENAI_USE_VERTEXAI=true (or USE_VERTEX_AI=true),
    GOOGLE_CLOUD_PROJECT, and optionally GOOGLE_CLOUD_LOCATION (default us-central1).
    """
    use_vertex = _truthy(os.getenv("GOOGLE_GENAI_USE_VERTEXAI")) or _truthy(
        os.getenv("USE_VERTEX_AI")
    )

    if use_vertex:
        project = os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GCP_PROJECT")
        location = os.getenv("GOOGLE_CLOUD_LOCATION", "us-central1")
        if not project:
            raise ValueError(
                "Vertex AI requires GOOGLE_CLOUD_PROJECT (or GCP_PROJECT). "
                "Set GOOGLE_GENAI_USE_VERTEXAI=true and authenticate with "
                "GOOGLE_APPLICATION_CREDENTIALS or Application Default Credentials."
            )
        return genai.Client(vertexai=True, project=project, location=location)

    api_key = os.getenv("API_KEY")
    if not api_key:
        raise ValueError(
            "Set API_KEY for the Gemini Developer API, or enable Vertex AI with "
            "GOOGLE_GENAI_USE_VERTEXAI=true and GOOGLE_CLOUD_PROJECT=..."
        )
    return genai.Client(api_key=api_key)


def default_model_name() -> str:
    """Model id for generate_content (override with GEMINI_MODEL)."""
    return os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
