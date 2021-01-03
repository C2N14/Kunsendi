import os
import sys
from pathlib import Path

file = Path(__file__).resolve()
sys.path.append(str(file.parents[1]))

from api.app import create_app
app = create_app()

if __name__ == '__main__':
    app.run()
