from dotenv import load_dotenv
import os

load_dotenv()

OPENAI_KEY = os.getenv("OPENAI_API_KEY")
STORAGE_KEY = os.getenv("NFT_STORAGE_API_KEY")

ORACLE_PACKAGE_ID = os.getenv("ORACLE_PACKAGE_ID")
PROMPTS_OBJECT_ID = os.getenv("PROMPTS_OBJECT_ID")
RESPONSES_OBJECT_ID = os.getenv("RESPONSES_OBJECT_ID")
FUNCTION_CALLS_OBJECT_ID = os.getenv("FUNCTION_CALLS_OBJECT_ID")
FUNCTION_RESPONSES_OBJECT_ID = os.getenv("FUNCTION_RESPONSES_OBJECT_ID")
VECTOR_SEARCH_OBJECT_ID = os.getenv("VECTOR_SEARCH_OBJECT_ID")
VECTOR_SEARCH_RESPONSES_OBJECT_ID = os.getenv("VECTOR_SEARCH_RESPONSES_OBJECT_ID")

POLL_TIMEOUT = int(os.getenv("POLL_TIMEOUT") or "60")

CHAIN_ID = os.getenv("CHAIN_ID")
WEB3_RPC_URL = os.getenv("WEB3_RPC_URL")
AGENT_ADDRESS = os.getenv("AGENT_ADDRESS")
AGENT_ABI_PATH = os.getenv("AGENT_ABI_PATH")

PRIVATE_KEY = os.getenv("PRIVATE_KEY")
assert WEB3_RPC_URL and AGENT_ADDRESS and AGENT_ABI_PATH and PRIVATE_KEY