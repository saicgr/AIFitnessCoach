"""Pydantic models for chat."""
from datetime import datetime, date
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class ChatHistoryItem(BaseModel):
    """Single chat history item."""
    id: str  # UUID string from Supabase
    role: str  # 'user' or 'assistant'
    content: str
    timestamp: str
    agent_type: Optional[str] = None  # "coach", "nutrition", "workout", "injury", "hydration"
    action_data: Optional[dict] = None
    is_pinned: bool = False
    audio_url: Optional[str] = None
    audio_duration_ms: Optional[int] = None
    coach_persona_id: Optional[str] = None  # Which coach persona sent this message
    media_url: Optional[str] = None  # Public S3 URL for image/video messages
    media_type: Optional[str] = None  # 'image' or 'video'


class PinToggleRequest(BaseModel):
    """Request body for toggling pin status on a chat message."""
    is_pinned: bool


class ChatSearchRequest(BaseModel):
    """Request body for chat history search."""
    query: str = Field(..., min_length=1, max_length=200)
    limit: int = Field(default=20, ge=1, le=50)


class ExtractIntentRequest(BaseModel):
    """Request for intent extraction."""
    message: str


class ExtractIntentResponse(BaseModel):
    """Response from intent extraction."""
    intent: str
    exercises: List[str] = []
    muscleGroups: List[str] = []
    modification: Optional[str] = None
    bodyPart: Optional[str] = None


class RAGSearchRequest(BaseModel):
    """Request for RAG search."""
    query: str
    n_results: int = 5
    user_id: Optional[str] = None  # UUID from Supabase


class RAGSearchResult(BaseModel):
    """Single RAG search result."""
    question: str
    answer: str
    intent: str
    similarity: float


class MediaPresignRequest(BaseModel):
    """Request body for generating a presigned S3 upload URL."""
    filename: str = Field(..., min_length=1, max_length=255, description="Original filename")
    content_type: str = Field(..., max_length=50, description="MIME type (e.g., 'video/mp4', 'image/jpeg')")
    media_type: str = Field(..., max_length=10, description="'image', 'video', or 'audio'")
    expected_size_bytes: int = Field(..., gt=0, description="Expected file size in bytes")


class MediaPresignResponse(BaseModel):
    """Response with presigned S3 POST URL and fields."""
    presigned_url: str = Field(..., description="URL to POST the file to")
    presigned_fields: Dict[str, str] = Field(..., description="Form fields to include in the POST")
    s3_key: str = Field(..., description="S3 object key for referencing in ChatRequest.media_ref")
    expires_in: int = Field(..., description="Seconds until the presigned URL expires")
    public_url: str = Field(..., description="Persistent public URL for the uploaded file")


class MediaUploadResponse(BaseModel):
    """Response from direct video upload — both S3 and Gemini file are ready."""
    s3_key: str
    public_url: str
    gemini_file_name: str  # e.g. "files/abc123xyz" — pass back in media_ref
    mime_type: str


class BatchPresignFileRequest(BaseModel):
    """Single file in a batch presign request."""
    filename: str = Field(..., min_length=1, max_length=255)
    content_type: str = Field(..., max_length=50)
    media_type: str = Field(..., max_length=10)
    expected_size_bytes: int = Field(..., gt=0)


class BatchPresignRequest(BaseModel):
    """Request body for batch presigned S3 upload URLs."""
    files: List[BatchPresignFileRequest] = Field(..., min_length=1, max_length=5)


class BatchPresignResponseItem(BaseModel):
    """Single item in a batch presign response."""
    presigned_url: str
    presigned_fields: Dict[str, str]
    s3_key: str
    expires_in: int
    public_url: str


class BatchPresignResponse(BaseModel):
    """Response with batch presigned S3 POST URLs."""
    items: List[BatchPresignResponseItem]


