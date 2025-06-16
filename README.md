# Climate Stripes Viewer

A simple web interface for viewing and downloading climate stripes visualizations for Eastern European countries.

## Features

- **Country Selection**: Choose from 30 Eastern European countries
- **Dual Chart View**: View both clean and labeled versions of climate stripes
- **Download Functionality**: Download charts in PNG format
- **Responsive Design**: Works on desktop and mobile devices
- **Modern UI**: Clean, intuitive interface with smooth animations

## Usage

1. Open `index.html` in a web browser
2. Select a country from the dropdown menu
3. View the climate stripes charts that appear
4. Hover over any chart to see the download button
5. Click the download button to save the chart to your device

## Chart Types

- **Clean**: Pure temperature stripes without labels - ideal for presentations or artistic use
- **Labels**: Temperature stripes with year markers and temperature scale for detailed analysis

## Technical Details

The application is built with:
- **HTML5**: Semantic structure
- **CSS3**: Modern styling with gradients, animations, and responsive grid
- **Vanilla JavaScript**: No external dependencies for fast loading

## Files Structure

```
├── index.html          # Main HTML file
├── styles.css          # CSS styling
├── script.js           # JavaScript functionality
├── publish/            # Chart images directory
│   ├── albania/
│   │   ├── clean.png
│   │   └── labels.png
│   └── [other countries...]
└── README.md           # This file
```

## Browser Compatibility

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## Data Source

Climate stripes are generated from Berkeley Earth temperature data, showing temperature anomalies over time as colored stripes.

## Local Development

To run locally:
1. Clone/download the repository
2. Open `index.html` in a web browser
3. Ensure the `publish/` directory contains the chart images

For production deployment, serve the files through a web server to avoid CORS issues with local file access.
