# ASCtoSEGY - Seismic Data Format Conversion Toolbox

[![Platform](https://img.shields.io/badge/platform-MATLAB%20%7C%20Octave-blue)](https://www.gnu.org/software/octave/)
[![License](https://img.shields.io/badge/license-GPL%20v2-green)](./LICENSE)

A MATLAB/Octave toolbox based on SegyMAT for reading, writing, and converting
seismic data formats. Extends the original library with support for ASC, SAC,
GSE, and SU format interconversion.

## Supported Formats

| Format | Read | Write | Notes |
|---|---|---|---|
| SEG-Y (Rev 0/1) | yes | yes | Industry standard for seismic |
| ASC | yes | to SEG-Y | Tabular text trace data |
| SAC | yes | to SEG-Y | SAC binary, PC, Sun variants |
| SU | yes | yes | Seismic Unix format |
| GSE | yes | to SEG-Y | GSE INT format |

## Quick Start

```matlab
addpath(genpath('/path/to/ASCtoSEGY'));

% Read a SEG-Y file
[Data, TraceHeaders, SegyHeader] = ReadSegy('survey.segy');

% Read a time slice
Data = ReadSegy('survey.segy', 'it', 123);

% Read by CDP range
Data = ReadSegy('survey.segy', 'minmax', 'cdp', 5000, 5800);

% Batch convert ASC to SEG-Y
ASCtoSGY3('X:/raw_data/', 'X:/output/');

% Convert SAC to SEG-Y
Sac2Segy('event.sac', 'event.segy');

% Write SEG-Y with geometry
WriteSegy('output.segy', data, 'dt', 0.004, ...
    'Inline3D', Inline, 'Crossline3D', Crossline);
```

Compatible with GNU Octave - see README_OCTAVE.

## Key Features

### SEG-Y I/O
- Full support for SEG-Y Revision 0 and Revision 1
- IBM Floating Point, IEEE Floating Point formats
- Selective read by trace number, CDP range, or time window
- Fast read mode (skip trace headers)
- Memory-efficient chunked reading

### Format Conversion
- ASC to SEG-Y: Batch merge with auto-detection
- SAC to SEG-Y: SAC binary, PC, and Sun variants
- GSE to SEG-Y: GSE INT format
- SU to/from SEG-Y: Seismic Unix conversion

### Visualization
- wiggle.m: Wiggle trace plot with variable-area fill
- Red-white-blue colormap, overlay support

## Core Functions

**SEG-Y I/O:**
  ReadSegy, WriteSegy, ReadSegyFast, WriteSegyFast
  ReadSegyHeader, GetSegyHeader, PutSegyHeader
  GetSegyTrace, PutSegyTrace, WriteSegyStructure

**SU I/O:**
  ReadSu, WriteSu, ReadSuFast, WriteSuStructure

**Format Converters:**
  ASCtoSGY3, Sac2Segy, gse2segy, Segy2Su, Su2Segy

**SAC Readers:**
  sac2mat, sacpc2mat, sacsun2mat

**Low-Level:**
  ibm2num, num2ibm, ascii2ebcdic, ebcdic2ascii

**Visualization:**
  wiggle, cmap_rwb

## About

Built on Thomas Mejer Hansen's SegyMAT (GPL v2), with extensions for
multi-format conversion and seismic data processing workflows.

> Hansen, T. M. (2019). SegyMAT. Zenodo. https://doi.org/10.5281/zenodo.1305289

## License

GNU General Public License v2 - see LICENSE
