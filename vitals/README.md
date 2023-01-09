## Building
```bash
npm install
npm run build
```

## Updating JS string in source
If updating web-vitals is necessary run the build instructions above and then copy the output:

```bash
cat dist/index.js | pbcopy
```

Then paste the contents into the script source in `PortalUIView.swift`.
This is not anticipated to be updated frequently, so no automation or code generation has been done for this.
