.PHONY: test matrix lint
test:
	pwsh -c "Invoke-Pester ./tests -CI"
matrix:
	pwsh ./tests/Invoke-ScenarioMatrix.ps1 -Quick
lint:
	terraform fmt -check -recursive templates
