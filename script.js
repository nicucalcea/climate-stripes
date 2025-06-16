// Available countries based on the publish directory structure
const countries = [
    { name: 'Albania', folder: 'albania' },
    { name: 'Armenia', folder: 'armenia' },
    { name: 'Azerbaijan', folder: 'azerbaijan' },
    { name: 'Belarus', folder: 'belarus' },
    { name: 'Bosnia & Herzegovina', folder: 'bosnia-&-herzegovina' },
    { name: 'Bulgaria', folder: 'bulgaria' },
    { name: 'Croatia', folder: 'croatia' },
    { name: 'Czechia', folder: 'czechia' },
    { name: 'Estonia', folder: 'estonia' },
    { name: 'Georgia', folder: 'georgia' },
    { name: 'Hungary', folder: 'hungary' },
    { name: 'Kazakhstan', folder: 'kazakhstan' },
    { name: 'Kosovo', folder: 'kosovo' },
    { name: 'Kyrgyzstan', folder: 'kyrgyzstan' },
    { name: 'Latvia', folder: 'latvia' },
    { name: 'Lithuania', folder: 'lithuania' },
    { name: 'Moldova', folder: 'moldova' },
    { name: 'Montenegro', folder: 'montenegro' },
    { name: 'North Macedonia', folder: 'north-macedonia' },
    { name: 'Poland', folder: 'poland' },
    { name: 'Romania', folder: 'romania' },
    { name: 'Russia', folder: 'russia' },
    { name: 'Serbia', folder: 'serbia' },
    { name: 'Slovakia', folder: 'slovakia' },
    { name: 'Slovenia', folder: 'slovenia' },
    { name: 'Tajikistan', folder: 'tajikistan' },
    { name: 'Turkey', folder: 'turkey' },
    { name: 'Turkmenistan', folder: 'turkmenistan' },
    { name: 'Ukraine', folder: 'ukraine' },
    { name: 'Uzbekistan', folder: 'uzbekistan' }
];

// DOM elements
const countrySelect = document.getElementById('country-select');
const chartsContainer = document.getElementById('charts-container');
const countryTitle = document.getElementById('country-title');
const cleanChart = document.getElementById('clean-chart');
const labelsChart = document.getElementById('labels-chart');
const downloadCleanBtn = document.getElementById('download-clean');
const downloadLabelsBtn = document.getElementById('download-labels');
const loadingElement = document.getElementById('loading');
const errorElement = document.getElementById('error');

// Initialize the application
function init() {
    populateCountrySelect();
    setupEventListeners();
}

// Populate the country select dropdown
function populateCountrySelect() {
    countries.forEach(country => {
        const option = document.createElement('option');
        option.value = country.folder;
        option.textContent = country.name;
        countrySelect.appendChild(option);
    });
}

// Setup event listeners
function setupEventListeners() {
    countrySelect.addEventListener('change', handleCountryChange);
    downloadCleanBtn.addEventListener('click', () => downloadChart('clean'));
    downloadLabelsBtn.addEventListener('click', () => downloadChart('labels'));
}

// Handle country selection change
function handleCountryChange() {
    const selectedCountry = countrySelect.value;
    
    if (!selectedCountry) {
        hideCharts();
        return;
    }
    
    loadCharts(selectedCountry);
}

// Load charts for the selected country
function loadCharts(countryFolder) {
    showLoading();
    hideError();
    
    const countryData = countries.find(c => c.folder === countryFolder);
    const countryName = countryData ? countryData.name : countryFolder;
    
    // Set country title
    countryTitle.textContent = `${countryName} Climate Stripes`;
    
    // Set image sources
    const cleanImagePath = `publish/${countryFolder}/clean.png`;
    const labelsImagePath = `publish/${countryFolder}/labels.png`;
    
    // Load images
    let imagesLoaded = 0;
    let hasError = false;
    
    const checkAllImagesLoaded = () => {
        imagesLoaded++;
        if (imagesLoaded === 2 && !hasError) {
            hideLoading();
            showCharts();
        }
    };
    
    const handleImageError = () => {
        hasError = true;
        hideLoading();
        showError();
        hideCharts();
    };
    
    // Clean chart
    cleanChart.onload = checkAllImagesLoaded;
    cleanChart.onerror = handleImageError;
    cleanChart.src = cleanImagePath;
    
    // Labels chart
    labelsChart.onload = checkAllImagesLoaded;
    labelsChart.onerror = handleImageError;
    labelsChart.src = labelsImagePath;
}

// Download chart function
async function downloadChart(chartType) {
    const selectedCountry = countrySelect.value;
    if (!selectedCountry) return;
    
    const countryData = countries.find(c => c.folder === selectedCountry);
    const countryName = countryData ? countryData.name : selectedCountry;
    
    const imagePath = `publish/${selectedCountry}/${chartType}.png`;
    const fileName = `${countryName.toLowerCase().replace(/\s+/g, '-')}-climate-stripes-${chartType}.png`;
    
    try {
        // Fetch the image
        const response = await fetch(imagePath);
        if (!response.ok) throw new Error('Failed to fetch image');
        
        const blob = await response.blob();
        
        // Create download link
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        
        // Cleanup
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
    } catch (error) {
        console.error('Download failed:', error);
        alert('Failed to download the chart. Please try again.');
    }
}

// Show/hide functions
function showLoading() {
    loadingElement.style.display = 'block';
}

function hideLoading() {
    loadingElement.style.display = 'none';
}

function showCharts() {
    chartsContainer.style.display = 'block';
}

function hideCharts() {
    chartsContainer.style.display = 'none';
}

function showError() {
    errorElement.style.display = 'block';
}

function hideError() {
    errorElement.style.display = 'none';
}

// Initialize the application when the DOM is loaded
document.addEventListener('DOMContentLoaded', init);
