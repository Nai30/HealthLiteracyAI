import os
from urllib import response
from dotenv import load_dotenv
from google import genai

#Setup api key and make client object for Gemini API
load_dotenv() # Loads the .env file(which holds the API key) into the environment
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

#Example Usage of process_document function
#result = process_document("sample_legal_doc.txt", "Spanish")
#print(result)

def process_document(file_path, target_language):
    try:
    # Read the document content
        with open(file_path, 'r', encoding='utf-8') as file:
            document_txt = file.read()

    except Exception as e:
        print(f"Error reading document: {e}")
   
    # Create a prompt for the Gemini API
    prompt = f"""
    You are a legal expert,process the following English legal document for a native {target_language} speaker:
    1. Provide a full, accurate translation of the document into {target_language}.
    Format the translated document in a way that is easy to read and navigate, using headings, bullet points, or other formating techniques as appropriate.
    
    2.Provide a simplified summary of the key terms and obligations. Extract the key information and main points from the document, summarizing it in a way that is easy to understand for someone who may not have a legal background.
    Use clear and simple language that is easy to understand for a native {target_language} speaker, avoiding complex legal jargon whenever possible.
    Provide explanations for any legal terms that may be necessary to understand the document.
    
    \n\n
    Document Text:
    {document_txt}
    """
    
    # response= Generated response using the client api object
    response = client.models.generate_content(
            model="gemini-2.5-flash", #model of choice
            contents = prompt         #prompt created above
            )
    if response.text: 
        return response.text
    else:
        return "Error: the model returned an empty response or was blocked by safety filters."