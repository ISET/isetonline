import "core-js/stable";
import "devextreme/dist/css/dx.light.css";
import React, { useState, useRef, useCallback, useEffect } from "react";
// not used yet:
// import { useEffect, useMemo } from 'react'
import "react-dom";

import { AgGridReact } from "ag-grid-react"; // the AG Grid React Component
// import MyStatusPanel from './myStatusPanel.jsx';

import "ag-grid-community/styles/ag-grid.css"; // Core grid CSS, always needed
import "ag-grid-community/styles/ag-theme-alpine.css"; // Optional theme CSS
import ImageRenderer from "./ImageRenderer.jsx";

// Core UI & Bootstrap
import "@coreui/coreui/dist/css/coreui.min.css";
import "bootstrap/dist/css/bootstrap.min.css";
import {
  CContainer,
  CButton,
  CButtonGroup,
  CForm,
  CRow,
  CCol,
  CImage,
  CFooter,
  CLink,
  CTooltip,
  CButtonToolbar,
} from "@coreui/react";
import {
  CTable,
  CTableHead,
  CTableRow,
  CTableBody,
  CTableHeaderCell,
  CTableDataCell,
} from "@coreui/react";

// MUI since it has some free bits that CoreUI doesn't
//import Stack from '@mui/material/Stack'
import Box from "@mui/material/Box";
import Slider from "@mui/material/Slider";

// JSON Editor
// import SvelteJSONEditor from "./sveltejsoneditor";
import "./styles.css";

// Additional components
import { saveAs } from "file-saver";
// import { PopupComponent } from 'ag-grid-community'

// for showing object labels
import { Annotorious } from "@recogito/annotorious";
// plugin to allow labels on shapes
//import { ShapeLabelsFormatter } from '@recogito/annotorious-shape-labels';
import "@recogito/annotorious/dist/annotorious.min.css";
import { breakpoints } from "@mui/system";

// Load our rendered sensor images
// They are located in sub-folders under /public
// NOTE: datadir + a subdir doesn't seem to work?
let dataDir = "./data/";
let imageDir = "/images/"; // Should use /public by default?
let sensorDir = "./data/sensors/";

let imageMetaData = require(dataDir + "metadata.json");
var imageData;

let SU_Logo = "/glyphs/Stanford_Logo.png";
let previewImage = SU_Logo; // imageDir + imageData[0].jpegName
let computedImage = SU_Logo; // imageDir + imageData[0].jpegName

// When the user selects a row, we will set the data files for possible download
let selectedImage = {
  sensorData: [],
  rgbData: [],
  oi: [],
};

// get sensorimage data from the metadata.json file.
// however, it is a map/collection, so we need to index into it first.
var rows = [];
var CT = [];
var CTDistance = 1000000;

for (let rr = 0; rr < imageMetaData.length; rr++) {
  imageData = imageMetaData[rr];

  // closestTarget seems a bit flakey, so check for existence
  if (imageData.hasOwnProperty('closestTarget')){
    CT = imageData.closestTarget;
    if (CT.hasOwnProperty('distance')){
      CTDistance = CT.distance;
    } else {
      CTDistance = 1000000
    }
  } else {
    CT = [];
    CTDistance = 1000000;
  }
  

  // Read image objects into grid rows
  // Some visible, some hidden for other uses
  let newRow = [
    {
      // Columns displayed to user
      thumbnail: imageDir + imageData.web.thumbnailName,
      scene: imageData.scenename,

      // For future
      illumination: imageData.illumination,

      lens: imageData.opticsname,
      sensor: imageData.sensorname,
      scenarioName: imageData.scenario,

      // pre-load sensor objects
      // sensorDir sometimes errors here? 
      // sensorObject: require(sensorDir + imageData.sensorFile + ".json"),
      // make it just the sensor json name for now!
      sensorFileName: sensorDir + imageData.sensorFile + ".json",

      // Used to set the file for the preview window
      preview: imageDir + imageData.web.jpegName,

      // For alternate capture methods
      burstPreview: imageDir + imageData.web.burstJPEGName,
      bracketPreview: imageDir + imageData.web.bracketJPEGName,

      // We only keep one Ground Truth version
      GTPreview: imageDir + imageData.web.GTName,

      // And our YOLO annotated versions
      YOLOPreview: imageDir + imageData.web.YOLOName,
      YOLOBurstPreview: imageDir + imageData.web.burstYOLOName,
      YOLOBracketPreview: imageDir + imageData.web.bracketYOLOName,

      // FLARE previews should go here once we have them
      //

      // Used for download files
      jpegFile: imageData.web.jpegName,
      sensorRawFile: imageDir + imageData.sensorRawFile,
      sensorRawName: imageData.sensorRawFile,
      oiName: imageData.oiFile,
      oiFileName: imageData.web.oiName,

      // Used for other metadata properties
      eTime: imageData.exposureTime,
      aeMethod: imageData.aeMethod,

      // Pixel info
      pixel: imageData.pixel,

      // Ground Truth Objects & Statistics
      GTObjects: imageData.GTObjects,
      GTStats: imageData.Stats,
      GTLabels: imageData.Stats.uniqueLabels,
      GTDistance: Number(CTDistance),

      // Closest Target data
      closestTarget: CT,
      closestLabel: CT.label,

      // Text version of lighting parameters
      lightSources: getLightParams(imageData),

      // Each lighting parameter broken out
      lightSky: imageData.lightingParams.skyL_wt,
      lightHead: imageData.lightingParams.headL_wt,
      lightStreet: imageData.lightingParams.streetL_wt,
      lightFlare: imageData.lightingParams.flare,
      lightOther: imageData.lightingParams.otherL_wt,
      lightLuminance: imageData.lightingParams.meanLuminance,

      // These need to come form the underlying scene when we generate
      // the sensorImage collection in the db.
      // project: imageData.project,
      // scenario: imageData.scenario,
    },
  ];
  rows = rows.concat(newRow);
}

function getLightParams(imageData) {
  var lightSources = "";
  if (typeof imageData.lightingParams != "undefined") {
    lightSources =
      "Sky: " +
      imageData.lightingParams.skyL_wt +
      " Head: " +
      imageData.lightingParams.headL_wt +
      " Street: " +
      imageData.lightingParams.streetL_wt +
      " Flare: " +
      imageData.lightingParams.flare;
  }
  return lightSources;
}

var userSensorContent = "";
function updateUserSensor(newContent) {
  // argh. Hard to call into our App to set things
  // maybe it can call out?
  // setUserSensor(newContent);
  userSensorContent = newContent;
  return newContent; // not used
}

const App = () => {
  // Ref to the image DOM element
  const imgEl = useRef();

  // The current Annotorious instance
  const [anno, setAnno] = useState();

  // Current drawing tool name
  const [tool, setTool] = useState("rect");

  // Init Annotorious when the component
  // mounts, and keep the current 'anno'
  // instance in the application state
  useEffect(() => {
    let annotorious = null;

    if (imgEl.current) {
      // Init
      annotorious = new Annotorious({
        image: imgEl.current,
        disableEditor: true,
        readOnly: true,
        // this doesn't work here!
        // formatter: Annotorious.ShapeLabelsFormatter()
      });

      // Attach event handlers here in case we want interactivity
      annotorious.on("createAnnotation", (annotation) => {
        console.log("created", annotation);
      });

      annotorious.on("updateAnnotation", (annotation, previous) => {
        console.log("updated", annotation, previous);
      });

      annotorious.on("deleteAnnotation", (annotation) => {
        console.log("deleted", annotation);
      });
    }

    // Keep current Annotorious instance in state
    setAnno(annotorious);

    // Cleanup: destroy current instance
    return () => annotorious.destroy();
  }, []);

  // Toggles current tool + button label
  const toggleTool = () => {
    if (tool === "rect") {
      setTool("polygon");
      anno.setDrawingTool("polygon");
    } else {
      setTool("rect");
      anno.setDrawingTool("rect");
    }
  };

  // display modes for toggling
  const captureType = useRef("single");
  const YOLOMode = useRef(false);

  const gridRef = useRef();
  const expSlider = useRef();

  // pieces to try out a sensor editor
  const sensorEditor = useRef();

  // This sets the content for the sensor editor
  // THIS ONE IS A TEMPLATE AND SET BEFORE ROW CLICK
  const [content, setContent] = useState({
    json: {
      name: "Select image to see sensor data",
    },
    text: undefined,
  });

  const [computeText, setComputeText] = useState("Compute...");

  // let the grid know which columns and what data to use
  const [rowData] = useState(rows);

  // Each Column Definition results in one Column.
  const [columnDefs] = useState([
    {
      headerName: "Thumbnail",
      width: 128,
      field: "thumbnail",
      cellRenderer: ImageRenderer,
    },
    {
      headerName: "Scene",
      field: "scene",
      width: 128,
      filter: true,
      sortable: true,
      resizable: true,
      tooltipField: "Filter and Sort by Scene name",
    },

    // Display the actual objects found in scene
    {
      headerName: "Objects",
      field: "GTLabels",
      filter: true,
      sortable: true,
      resizable: true,
      tooltipField: "Objects in Scene",
      hide: false,
    },

    {
      headerName: "Distance",
      field: "GTDistance",
      width: 96,
      filter: "agNumberColumnFilter",
      sortable: true,
      tooltipField: "Minimum Object Distance",
      hide: false,
      valueFormatter: formatDistance,
    },

    {
      headerName: "Lens Used",
      field: "lens",
      filter: true,
      sortable: true,
      resizable: true,
      tooltipField: "Filter and sort by lens",
      hide: true,
    },
    {
      headerName: "Sensor",
      field: "sensor",
      width: 128,
      filter: true,
      sortable: true,
      resizable: true,
      tooltipField: "Filter and sort by sensor",
    },
    {
      headerName: "Scenario",
      field: "scenarioName",
      width: 128,
      filter: true,
      sortable: true,
      resizable: true,
      tooltipField: "Filter and sort by lighting scenario",
    },
    // Don't display text light sources if we display all of them separately
    {
      headerName: "Light Sources",
      field: "lightSources",
      filter: true,
      sortable: true,
      resizable: true,
      tooltipField: "Text version of light weightings",
      hide: true,
    },

    // Additional fields that may be useful for sorting & filtering
    {
      headerName: "Closest",
      field: "closestLabel",
      width: 128, 
      sortable: true,
      resizable: true,
      filter: true,
    },
    {
      headerName: "Skylight",
      field: "lightSky",
      width: 96, 
      sortable: true,
      resizable: true,
      filter: true,
    },
    {
      headerName: "StreetLamps",
      field: "lightStreet",
      width: 96, 
      sortable: true,
      resizable: true,
      filter: true,
    },
    {
      headerName: "Headlights",
      field: "lightHead",
      width: 96, 
      sortable: true,
      resizable: true,
      filter: true,
    },
    {
      headerName: "Other Light",
      field: "lightOther",
      width: 96, 
      sortable: true,
      resizable: true,
      filter: true,
    },
    {
      headerName: "Flare",
      field: "lightFlare",
      width: 96, 
      sortable: true,
      resizable: true,
      filter: true,
    },
    {
      headerName: "Luminance",
      field: "lightLuminance",
      width: 128,
      sortable: true,
      resizable: true,
      filter: true,
    },

    // Hidden fields for addtional info
    { headerName: "Preview", field: "preview", hide: true },
    { headerName: "jpegName", field: "jpegName", hide: true },
    { headerName: "sensorRawFile", field: "sensorRawFile", hide: true },
    { headerName: "sensorRawName", field: "sensorRawName", hide: true },
    { headerName: "oiName", field: "oiName", hide: true },
    { headerName: "AE-Method", field: "aeMethod", hide: true },
    { headerName: "ExposureTime", field: "eTime", hide: true },
    { headerName: "Pixel", field: "pixel", hide: true },
    { headerName: "Burst Preview", field: "burstPreview", hide: true },
    { headerName: "Bracket Preview", field: "bracketPreview", hide: true },
    { headerName: "YOLO Preview", field: "YOLOPreview", hide: true },
    { headerName: "GT Preview", field: "GTPreview", hide: true },
    { headerName: "YOLO Burst Preview", field: "YOLOBurstPreview", hide: true },
    {
      headerName: "YOLO Bracket Preview",
      field: "YOLOBracketPreview",
      hide: true,
    },
    // We don't currently provide the Raw for burst & bracket
    // TBD: Other burst & bracket frame numbers &/or f-Stops
  ]);

  function formatDistance(params) {
    var distance = params.value;
    distance = distance.toFixed(1);
    if (distance < 10000) {
      return distance + " m";
    } else {
      return "none";
    }
  }
  const fSlider = useRef([]); // This will be the preview image element & Slider
  const selectedRow = useRef([]); // for use later when we need to download

  // Image Previews
  const pI = useRef("");
  const cI = useRef("");

  const currentSensor = useRef("");
  const [userSensor, setUserSensor] = useState("");

  // This is where we can add ability to call our compiled Matlab code
  const btnComputeListener = useCallback((event) => {
    cI.current = document.getElementById("computedImage");

    // get content from the sensor editor to use for this
    //var ourEdit = document.getElementById('sensorID')
    setComputeText("Computing...");
    // create a new timestamp
    var timestamp = new Date().getTime();
    cI.current.src = SU_Logo + "?t=" + timestamp;

    const requestOptions = {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sensor: userSensorContent,
        oiName: selectedRow.current.oiFileName,
        name: selectedRow.current.name,
      }),
    };

    var responseText = "";
    // Our dev and test servers
    var devServer = "http://seedling:3001";
    var testServer = "http://isetonline.dscloud.me:3001";

    fetch(testServer + "/compute", requestOptions)
      .then((response) => response.text())
      .then((rText) => {
        console.log("Response is: " + rText);
        setComputeText("Re-compute");
      })
      // show our re-calced image
      .then((useFile) => {
        timestamp = new Date().getTime();
        cI.current.src =
          testServer + "/images/sensorImage.png" + "?t=" + timestamp;
      });
  }, []);

  // When the user changes the type of exposure calculation
  // we change the preview and possibly also the number of frames
  const btnExposureListener = useCallback((event) => {
    pI.current = document.getElementById("previewImage");
    fSlider.current = document.getElementById("frameSlider");
    var ourButton = document.getElementById(event.target.id);

    // need to also change the DL file(s)
    switch (event.target.id) {
      case "buttonAE":
        // put back the default preview
        if (YOLOMode.current) {
          pI.current.src = selectedRow.current.YOLOPreview;
        } else {
          pI.current.src = selectedRow.current.preview;
        }
        selectedImage.rgbData = selectedRow.current.previewImage;
        setValue(1); // sets the number of frames slider
        captureType.current = "single";
        break;

      case "buttonBurst":
        // show the burst image
        if (YOLOMode.current) {
          pI.current.src = selectedRow.current.YOLOBurstPreview;
        } else {
          pI.current.src = selectedRow.current.burstPreview;
        }
        selectedImage.rgbData = selectedRow.current.burstPreview;
        setValue(5);
        captureType.current = "burst";
        break;

      case "buttonBracket":
        // show the bracketed image
        if (YOLOMode.current) {
          pI.current.src = selectedRow.current.YOLOBracketPreview;
        } else {
          pI.current.src = selectedRow.current.bracketPreview;
        }
        selectedImage.rgbData = selectedRow.current.bracketPreview;
        setValue(3);
        captureType.current = "bracket";
        break;

      // show the ground truth
      case "buttonGT":
        pI.current.src = selectedRow.current.GTPreview;
        break;

      // show the results of our YOLO function for each exposure type
      case "buttonYOLO":
        // Show /toggle YOLO annotations
        if (YOLOMode.current === false) {
          YOLOMode.current = true;
          ourButton.innerHTML = "Hide YOLO";
          switch (captureType.current) {
            case "single":
              pI.current.src = selectedRow.current.YOLOPreview;
              break;
            case "burst":
              pI.current.src = selectedRow.current.YOLOBurstPreview;
              break;
            case "bracket":
              pI.current.src = selectedRow.current.YOLOBracketPreview;
              break;
            default:
              // Shouldn't happen
              break;
          }
        } else {
          YOLOMode.current = false;
          ourButton.innerHTML = "Show YOLO";
          switch (captureType.current) {
            case "single":
              pI.current.src = selectedRow.current.preview;
              break;
            case "burst":
              pI.current.src = selectedRow.current.burstPreview;
              break;
            case "bracket":
              pI.current.src = selectedRow.current.bracketPreview;
              break;
            default:
              // shouldn't get here
              break;
          }
        }
        break;
      default:
        // Shouldn't happen
        break;
    }
  }, []);

  const rowClickedListener = useCallback((event) => {
    //console.log('Row Clicked: \n', event)
    setValue(1); // always start with 1 frame AE, at least for now
    selectedRow.current = event.data;
    pI.current = document.getElementById("previewImage");

    // load the selected sensor in case the user wants
    // to modify its parameters and recompute
    //
    var factorySensorFile = selectedRow.current.sensorFileName;
    var sensorObject = require(factorySensorFile);
    var dataPrepSensorFile = factorySensorFile.replace(
      ".json",
      "-Baseline.json"
    );
    // Fetch Function
    fetch("/sensors/" + dataPrepSensorFile)
      .then(function (res) {
        return res.json();
      })
      .then(function (data) {
        // store Data in State Data Variable
        setContent({
          json: data,
          text: undefined,
        });
      })
      .catch(function (err) {
        console.log(err, " error");
      });

    // Set the baseline user sensor
    setUserSensor(currentSensor.current);

    console.log(currentSensor.current);

    // We should clearly add a 'setter' to the Mode
    YOLOMode.current = false;
    var ourButton = document.getElementById("buttonYOLO");
    ourButton.innerHTML = "Show YOLO";

    pI.current.src = selectedRow.current.preview;
    selectedImage.rgbData = selectedRow.current.previewImage;

    // Change preview caption
    var pCaption, eTime, aeMethod;
    pCaption = document.getElementById("previewCaption");
    pCaption.textContent = selectedRow.current.jpegFile;

    // Update Image property table
    eTime = document.getElementById("eTime");
    var exposureTime = selectedRow.current.eTime;
    eTime.textContent = exposureTime.toFixed(4) + " seconds";
    aeMethod = document.getElementById("aeMethod");
    aeMethod.textContent = selectedRow.current.aeMethod;

    // Update Pixel property table
    var pWidth, pHeight, pConversionGain, pVoltageSwing;
    pWidth = document.getElementById("pWidth");
    pHeight = document.getElementById("pHeight");
    pWidth.textContent =
      (event.data.pixel.width * 1000000).toFixed(2) + " microns";
    pHeight.textContent =
      (event.data.pixel.height * 1000000).toFixed(2) + " microns";
    pConversionGain = document.getElementById("pConversionGain");
    pVoltageSwing = document.getElementById("pVoltageSwing");
    pConversionGain.textContent = selectedRow.current.pixel.conversionGain;
    pVoltageSwing.textContent = selectedRow.current.pixel.voltageSwing;
  }, []);

  // Handle download buttons
  const buttonDownload = useCallback((event) => {
    let dlName = "";
    let dlPath = "";
    if (selectedRow.current === undefined) {
      window.alert("You need to select a sensor image first.");
      return;
    }
    // Need to figure out which scene & which file
    // TBD: Add support for DL burst/bracket variants
    switch (event.currentTarget.id) {
      case "dlSensorVolts":
        dlPath = selectedRow.current.sensorRawFile;
        dlName = selectedRow.current.sensorRawName;
        break;
      case "dlIPRGB":
        dlPath = selectedRow.current.preview;
        dlName = selectedRow.current.jpegFile;
        break;
      case "dlOI":
        // Some OI may be too large, but so far so good
        dlPath = selectedRow.current.oiImageName;
        dlName = selectedRow.current.oiImageName;
        break;
      default:
      // Nothing
    }
    console.log(process.env.PUBLIC_URL);
    console.log(dlPath);
    console.log(dlName);
    saveAs(process.env.PUBLIC_URL + dlPath, dlName);
  }, []);

  // for now open the preview image in a new window
  // might want to do more interesting things later
  const previewClick = useCallback((event) => {
    var ourImage = document.getElementById("previewImage");
    window.open(ourImage.src);
  }, []);

  const expMarks = [
    {
      value: 1,
      label: "1",
    },
    {
      value: 3,
      label: "3",
    },
    {
      value: 5,
      label: "5",
    },
  ];

  const [value, setValue] = useState(1);

  const changeValue = (event, value) => {
    setValue(value);
  };

  const [showEditor, setShowEditor] = useState(true);
  const [readOnly, setReadOnly] = useState(false);

  // JSX (e.g. HTML +) STARTS HERE
  // -----------------------------

  return (
    <CContainer fluid>
      {/* Row 1 is our Header & README*/}
      <CRow className="justify-content-start">
        <CCol xs={1}>
          <CImage width="100" src={SU_Logo}></CImage>
        </CCol>
        <CCol xs={4}>
          <CImage width="300" src="/glyphs/Vista_Lab_Logo.png"></CImage>
          <h2>ISET Online</h2>
        </CCol>
        <CCol xs={7}>
          <p>
            <br></br>Choose from our library of scenes to get a highly-accurate
            simulated image as it would be rendered using a selected sensor. You
            can see the Ground Truth of objects in the scene, as well as the
            results from YOLOv4 using auto-exposure, burst, and bracketing.
          </p>
        </CCol>
      </CRow>

      {/* Try Row 2 as everything else */}
      <CRow className="align-items-start">
        {/* First column is grid + Proper */}
        <CCol xs={7} className="align-items-start">
          {/* First row is grid */}
          <CRow>
            <div
              className="ag-theme-alpine"
              style={{ width: 900, height: 400 }}
            >
              <AgGridReact
                ref={gridRef} // Ref for accessing Grid's API
                rowData={rowData} // Row Data for Rows
                columnDefs={columnDefs} // Column Defs for Columns
                animateRows={true} // Optional - set to 'true' to have rows animate when sorted
                rowSelection="single" // Options - allows click selection of rows
                onRowClicked={rowClickedListener} // Optional - registering for Grid Event
              />
            </div>
          </CRow>

          {/* Second Row is Props Tables */}
          <CRow>
            <CCol>
              <CTable>
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell scope="col">
                      <h5>Image Properties:</h5>
                    </CTableHeaderCell>
                    <CTableHeaderCell scope="col">
                      <h5>Value:</h5>
                    </CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody id="imageProps">
                  <CTableRow color="primary">
                    <CTableDataCell>Expsoure:</CTableDataCell>
                    <CTableDataCell id="eTime">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="secondary">
                    <CTableDataCell>AE Method</CTableDataCell>
                    <CTableDataCell id="aeMethod">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="primary">
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="secondary">
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="primary">
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                </CTableBody>
              </CTable>
            </CCol>
            {/* For now next column is Pixel props */}
            <CCol>
              <CTable>
                <CTableHead>
                  <CTableRow>
                    <CTableHeaderCell scope="col">
                      <h5>Pixel Properties:</h5>
                    </CTableHeaderCell>
                    <CTableHeaderCell scope="col">
                      <h5>Value:</h5>
                    </CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody id="pixelProps">
                  <CTableRow color="primary">
                    <CTableDataCell>Width:</CTableDataCell>
                    <CTableDataCell id="pWidth">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="secondary">
                    <CTableDataCell>Height:</CTableDataCell>
                    <CTableDataCell id="pHeight">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="primary">
                    <CTableDataCell>Conversion Gain:</CTableDataCell>
                    <CTableDataCell id="pConversionGain">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="secondary">
                    <CTableDataCell>Voltage Swing:</CTableDataCell>
                    <CTableDataCell id="pVoltageSwing">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color="primary">
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                </CTableBody>
              </CTable>
            </CCol>
          </CRow>
          <CRow>
            <CCol>
              {/* JSON Editor for sensor object */}
              <div className="App" style={{ width: 300 }}>
                {/* If we want to use the raw json
      <p>
        <label>
          <input
            type="checkbox"
            checked={showEditor}
            onChange={() => setShowEditor(!showEditor)}
          />{" "}
          Show JSON editor
        </label>
      </p> */}
                {/* If we want a read-only option
      <p>
        <label>
          <input
            type="checkbox"
            checked={readOnly}
            onChange={() => setReadOnly(!readOnly)}
          />{" "}
          Read only
        </label>
      </p> */}

                {showEditor && (
                  <>
                    <h2>
                      Sensor Editor:
                      <CButton onClick={btnComputeListener}>
                        {computeText}
                      </CButton>
                    </h2>

                    <div className="my-editor" style={{ width: 300 }}>
                      {/*
                      <SvelteJSONEditor
                        id='sensorID'
                        ref={sensorEditor}
                        content={content}
                        readOnly={false}
                        onChange={setContent}
                      />
                      */}
                    </div>
                  </>
                )}

                {/* If we want to show contents
      <>
        <h2>Contents</h2>
        <pre>
          <code>{JSON.stringify(content, null, 2)}</code>
        </pre>
      </> */}
              </div>
            </CCol>
            <CCol style={{ width: 300 }}>
              {" "}
              {/* put re-computed preview here for now*/}
              <CImage
                id="computedImage"
                rounded
                thumbnail
                width={400}
                height={300}
                src={computedImage}
              />
            </CCol>
          </CRow>
        </CCol>
        <CCol xs={4}>
          <CRow className="align-items-center">
            <CButton
              style={{ background: "none", border: "none" }}
              onClick={previewClick}
            >
              <CImage
                id="previewImage"
                ref={imgEl}
                rounded
                thumbnail
                src={previewImage}
              />
            </CButton>
          </CRow>
          <CRow className="align-items-center">
            <h5>Preview of Selected Sensor Image:</h5>
            <p id="previewCaption"> No image selected </p>
          </CRow>
          <CRow>
            <h5>Exposure Options:</h5>
            <CButtonGroup role="group" aria-label="Exposure Options:">
              <CTooltip content="Simple Auto-Exposure">
                <CButton
                  variant="outline"
                  data-tip="Simple Auto-Exposure"
                  color="primary"
                  id="buttonAE"
                  onClick={btnExposureListener}
                >
                  {" "}
                  AE
                </CButton>
              </CTooltip>
              <CTooltip content="Multi-frame Burst">
                <CButton
                  variant="outline"
                  color="primary"
                  id="buttonBurst"
                  onClick={btnExposureListener}
                >
                  {" "}
                  Burst
                </CButton>
              </CTooltip>
              <CTooltip content="Multi-frame Bracket">
                <CButton
                  variant="outline"
                  color="primary"
                  id="buttonBracket"
                  onClick={btnExposureListener}
                >
                  {" "}
                  Bracket
                </CButton>
              </CTooltip>
            </CButtonGroup>
          </CRow>
          <CRow>
            <h5>Frames Captured:</h5>
            <Box>
              <Slider
                id="frameSlider"
                ref={expSlider}
                aria-label="Number of Frames"
                defaultValue={3}
                min={1}
                max={5}
                step={2}
                marks={expMarks}
                value={value}
                onChange={changeValue}
              />
            </Box>
          </CRow>
          <CRow>
            <h5>Download:</h5>
            <CButtonGroup>
              <CTooltip content="Sensor object, including its response in volts.">
                <CButton
                  id="dlSensorVolts"
                  variant="outline"
                  onClick={buttonDownload}
                >
                  Sensor Object
                </CButton>
              </CTooltip>
              <CTooltip content="Example RGB result (JPEG) after processing the sensor data.">
                <CButton
                  id="dlIPRGB"
                  variant="outline"
                  onClick={buttonDownload}
                >
                  Sensor Image
                </CButton>
              </CTooltip>
              <CTooltip content="A visual (JPEG) of the scene lit using this Scenario.">
                <CButton id="dlOI" variant="outline" onClick={buttonDownload}>
                  Image of Scene
                </CButton>
              </CTooltip>
            </CButtonGroup>
          </CRow>
        </CCol>
        <CCol xs={1}>
          <h5>Labels:</h5>
          {/* Label-related buttons */}
          <CButtonGroup vertical>
            <CButton
              id="buttonYOLO"
              variant="outline"
              onClick={btnExposureListener}
            >
              Show YOLO
            </CButton>
            <CButton
              id="buttonGT"
              variant="outline"
              onClick={btnExposureListener}
            >
              Ground Truth
            </CButton>
          </CButtonGroup>
          <h5>Compute:</h5>
          <CButton
            id="buttonCompute"
            variant="outline"
            onClick={btnComputeListener}
          >
            TEST Only
          </CButton>
        </CCol>
      </CRow>

      <CFooter>
        <div>
          <span>&copy; 2022-2023 VistaLab, Stanford University</span>
        </div>
        <div>
          <span>...</span>
          <CLink href="https://vistalab.stanford.edu">VistaLab Team</CLink>
        </div>
      </CFooter>
    </CContainer>
  );
};
export { App, updateUserSensor };
