import sys
from pathlib import Path
package_path = Path(__file__).parent
path = package_path.parent

if path not in sys.path:
    sys.path.append(path)
