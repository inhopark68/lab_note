from pydantic import BaseModel

class IdsIn(BaseModel):
    ids: list[int]
