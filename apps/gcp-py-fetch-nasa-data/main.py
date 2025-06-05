from modules import MODULE_REGISTRY as registry # <--- 修改在这里

def main(request=None, context=None): # Cloud Functions for event-driven functions usually take (event, context)
    # For a Pub/Sub trigger, 'request' will be the Pub/Sub message (event data)
    # and 'context' will be metadata about the event.
    # We might not use them directly if the function always processes all modules.
    
    print("Function ns-func-fetch-nasa-data triggered.") # 添加一些日志

    for name, handler in registry.items(): # 现在 registry 引用的是 MODULE_REGISTRY
        try:
            print(f"Processing module: {name}")
            handler()
            print(f"Successfully processed module: {name}")
        except Exception as e:
            print(f"Error processing module {name}: {e}")
            # Consider more robust error handling here, e.g., logging the full traceback
            # import traceback
            # print(traceback.format_exc())

    print("Function ns-func-fetch-nasa-data finished processing.")