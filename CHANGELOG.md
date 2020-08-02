
<a name="v0.0.2"></a>
## [v0.0.2](https://github.com/trinitronx/range2cidr/compare/v0.0.1...v0.0.2)

> 2020-08-02

### Bug Fixes

* Use realpath to find script absolute path (Fixes [#7](https://github.com/trinitronx/range2cidr/issues/7))
* Deadlock and multithreading bugs (Fixes [#3](https://github.com/trinitronx/range2cidr/issues/3))
* Multi-platform font paths! Fixes [#2](https://github.com/trinitronx/range2cidr/issues/2)
* Update requirements.txt for security (Fixes [#1](https://github.com/trinitronx/range2cidr/issues/1) Pillow: CVE-2019-19911, CVE-2020-5313, CVE-2019-16865)
* Adding Dependencies & pip requirements to README
* **README:** Prefer python >= 3.7 for multithreading / Queue fixes

### Features

* Implement fallback CPU count methods (Fixes [#5](https://github.com/trinitronx/range2cidr/issues/5))
* **CHANGELOG:** Use `git-chglog` for CHANGELOG.md generation

### Update Docs


- README.md


<a name="v0.0.1"></a>
## v0.0.1

> 2020-07-26

* Add more debug info
* Fix num_cpu on systems without "sysctl -n hw.cpu"
* README formatting
* Update README with list of scripts & new script Usage
* Improve mp4 conversion script: support command line flags & positional input/output options at bare minimum
* Adding README & LICENSE
* Adding scripts for timestamp overlay to phototimer images & converting to mp4 video
