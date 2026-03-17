import os
import json
from dotenv import load_dotenv
from google import genai

# Setup API
load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

def process_document(file_path, target_language):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            document_content = file.read()
    except Exception as e:
        return f"Error reading file: {e}"

    # Define the 'Contract' for the output
    # This tells Gemini exactly what keys to use in the JSON
    response_schema = {
        "type": "OBJECT",
        "properties": {
            "document_type": {"type": "STRING"},
            "summary_simple_english": {"type": "STRING"},
            "summary_translated": {"type": "STRING"},
            "key_findings": {
                "type": "ARRAY",
                "items": {
                    "type": "OBJECT",
                    "properties": {
                        "test_name": {"type": "STRING"},
                        "status": {"type": "STRING", "description": "Normal, Low, or High"},
                        "explanation": {"type": "STRING", "description": "Simple explanation of what this test means"}
                    }
                }
            },
            "full_translation": {"type": "STRING"}
        },
        "required": ["document_type", "summary_simple_english", "summary_translated", "key_findings"]
    }

    prompt = f"""
    You are a medical and legal expert. Process the following document for a {target_language} speaker.
    
    1. Identify if this is a medical report or legal doc.
    2. Provide a 5th-grade level summary in both English and {target_language}.
    3. For lab results, explain what the values mean in simple terms (e.g., 'Low Hemoglobin means your blood might not be carrying enough oxygen').
    
    Document Content:
    {document_content}
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
            config={
                "response_mime_type": "application/json",
                "response_schema": response_schema
            }
        )

        # Parse the string into a real Python dictionary to verify it's valid JSON
        structured_data = json.loads(response.text)
        return structured_data

    except Exception as e:
        return f"AI Processing Error: {e}"

# Run the test
result = process_document("sample_lab.json", "Spanish")
print(json.dumps(result, indent=2))