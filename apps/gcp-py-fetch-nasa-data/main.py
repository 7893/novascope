from modules import registry

def main(request=None, context=None):
    for name, handler in registry.MODULE_REGISTRY.items():
        try:
            handler()
        except Exception as e:
            print(f"Error processing {name}: {e}")
