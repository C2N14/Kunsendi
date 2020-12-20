def initialize_debugger():
    import multiprocessing

    print(multiprocessing.current_process().pid, flush=True)
    if multiprocessing.current_process().pid > 1:
        import debugpy

        debugpy.listen(('0.0.0.0', 5678))
        print('Waiting for debugger...', flush=True)
        debugpy.wait_for_client()
        print('Debugger connected', flush=True)
