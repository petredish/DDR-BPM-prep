import env
from pathlib import Path


class SimfileRes:

    def __init__(self, path: Path) -> None:
        self.name = path.name
        self.simfile = self.findSimfile(path)
        self.jacket = self.findJacket(path)
        self.banner = self.findBanner(path)
        self.ssc = self.simfile.suffix == ".ssc"

    def checkNaming(self):
        if not self.simfile:
            env.logger.error(f"Simfile not found for {self.name}")
            raise RuntimeError
        if not self.jacket:
            env.logger.error(f"Jacket not found for {self.jacket}.")
            raise RuntimeError

    def to_dict(self):
        props = ["simfile", "jacket"]
        return {prop: str(getattr(self, prop).name) for prop in props}

    def findFile(self, filename: Path) -> Path:
        if filename.exists():
            return filename
        else:
            env.logger.info(f"Failed to find {filename}")
            return Path()

    def findSimfile(self, foldername: Path) -> Path:
        for stem in [self.name, self.name.lstrip(".")]:
            for ext in [".sm", ".ssc"]:
                path = self.findFile(foldername / (stem + ext))
                if path != Path():
                    return path
        return Path()

    def findJacket(self, foldername: Path) -> Path:
        return self.findFile(foldername / (self.name + "-jacket.png"))

    def findBanner(self, foldername: Path) -> Path:
        return self.findFile(foldername / (self.name + ".png"))
