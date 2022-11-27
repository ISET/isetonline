import React, { useState, useRef, useCallback, useEffect } from 'react'
// not used yet:
// import { useEffect, useMemo } from 'react'
import 'react-dom'

import { AgGridReact } from 'ag-grid-react' // the AG Grid React Component
// import MyStatusPanel from './myStatusPanel.jsx';

import 'ag-grid-community/styles/ag-grid.css' // Core grid CSS, always needed
import 'ag-grid-community/styles/ag-theme-alpine.css' // Optional theme CSS
import ImageRenderer from './ImageRenderer.jsx'

// Core UI & Bootstrap
import '@coreui/coreui/dist/css/coreui.min.css'
import 'bootstrap/dist/css/bootstrap.min.css'
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
  CButtonToolbar
} from '@coreui/react'
import {
  CTable,
  CTableHead,
  CTableRow,
  CTableBody,
  CTableHeaderCell,
  CTableDataCell
} from '@coreui/react'

// MUI since it has some free bits that CoreUI doesn't
//import Stack from '@mui/material/Stack'
import Box from '@mui/material/Box'
import Slider from '@mui/material/Slider'

// JSON Editor
import SvelteJSONEditor from "./sveltejsoneditor";
import "./styles.css";

// Additional components
import { saveAs } from 'file-saver'
// import { PopupComponent } from 'ag-grid-community'

// for showing object labels
import { Annotorious } from '@recogito/annotorious'
// plugin to allow labels on shapes
//import { ShapeLabelsFormatter } from '@recogito/annotorious-shape-labels';
import '@recogito/annotorious/dist/annotorious.min.css'
import { breakpoints } from '@mui/system'

// Load our rendered sensor images
// They are located in sub-folders under /public
let dataDir = './data/'
let imageDir = '/images/' // Should use /public by default?
let oiDir = '/oi/'
let sensorDir = dataDir + 'sensors/'

let imageData = require(dataDir + 'metadata.json')

let SU_Logo = '/glyphs/Stanford_Logo.png'
let previewImage = SU_Logo // imageDir + imageData[0].jpegName
let computedImage = SU_Logo // imageDir + imageData[0].jpegName

// When the user selects a row, we will set the data files for possible download
let selectedImage = {
  sensorData: [],
  rgbData: [],
  oi: []
}



var rows
for (let ii = 0; ii < imageData.length; ii++) {
  // Read image objects into grid rows
  // Some visible, some hidden for other uses
  let newRow = [
    {
      // Columns displayed to user
      thumbnail: imageDir + imageData[ii].thumbnailName,
      scene: imageData[ii].scenename,

      // Just some demo data
      illumination: imageData[ii].illumination,

      lens: imageData[ii].opticsname,
      sensor: imageData[ii].sensorname,

      // pre-load sensor objects
      sensorObject: require(sensorDir + imageData[ii].sensorFile + '.json'),

      // Used to set the file for the preview window
      preview: imageDir + imageData[ii].jpegName,

      // And for alternate versions
      // Right now just burst & bracket
      // We should probably have a more general
      // "variants" based scheme
      burstPreview: imageDir + imageData[ii].burstJPEGName,
      bracketPreview: imageDir + imageData[ii].bracketJPEGName,

      // And our YOLO annotated versions
      YOLOPreview: imageDir + imageData[ii].YOLOName,
      YOLOBurstPreview: imageDir + imageData[ii].burstYOLOName,
      YOLOBracketPreview: imageDir + imageData[ii].bracketYOLOName,

      // Used for download files
      jpegFile: imageData[ii].jpegName,
      sensorRawFile: imageDir + imageData[ii].sensorRawFile,
      sensorRawName: imageData[ii].sensorRawFile,
      oiName: imageData[ii].oiFile,

      // Used for other metadata properties
      eTime: imageData[ii].exposureTime,
      aeMethod: imageData[ii].aeMethod,

      // Pixel info
      pixel: imageData[ii].pixel
    }
  ]
  if (ii === 0) {
    rows = newRow
  } else {
    rows = rows.concat(newRow)
  }
}

var userSensorContent = '';
function updateUserSensor(newContent) {
  // argh. Hard to call into our App to set things
  // maybe it can call out?
  // setUserSensor(newContent);
  userSensorContent = newContent;
  return (newContent); // not used 
}

const App = () => {


  // Ref to the image DOM element
  const imgEl = useRef()
  const computedEl = useRef()

  // The current Annotorious instance
  const [anno, setAnno] = useState()

  // Current drawing tool name
  const [tool, setTool] = useState('rect')

  // Init Annotorious when the component
  // mounts, and keep the current 'anno'
  // instance in the application state
  useEffect(() => {
    let annotorious = null

    if (imgEl.current) {
      // Init
      annotorious = new Annotorious({
        image: imgEl.current,
        disableEditor: true,
        readOnly: true
        // this doesn't work here!
        // formatter: Annotorious.ShapeLabelsFormatter()
      })

      // Attach event handlers here in case we want interactivity
      annotorious.on('createAnnotation', annotation => {
        console.log('created', annotation)
      })

      annotorious.on('updateAnnotation', (annotation, previous) => {
        console.log('updated', annotation, previous)
      })

      annotorious.on('deleteAnnotation', annotation => {
        console.log('deleted', annotation)
      })
    }

    // Keep current Annotorious instance in state
    setAnno(annotorious)

    // Cleanup: destroy current instance
    return () => annotorious.destroy()
  }, [])

  // Toggles current tool + button label
  const toggleTool = () => {
    if (tool === 'rect') {
      setTool('polygon')
      anno.setDrawingTool('polygon')
    } else {
      setTool('rect')
      anno.setDrawingTool('rect')
    }
  }

  // display modes for toggling
  const captureType = useRef('single')
  const YOLOMode = useRef(false)

  const gridRef = useRef()
  const expSlider = useRef()

  // pieces to try out a sensor editor
  const sensorEditor = useRef()

  // This sets the content for the sensor editor
  // THIS ONE IS A TEMPLATE AND SET BEFORE ROW CLICK

  const [content, setContent] = useState(
    {
      json: {
        name: "Select image to see sensor data"
      },
      text: undefined
    });

  // let the grid know which columns and what data to use
  const [rowData] = useState(rows)

  // Each Column Definition results in one Column.
  const [columnDefs] = useState([
    {
      headerName: 'Thumbnail',
      width: 128,
      field: 'thumbnail',
      cellRenderer: ImageRenderer
    },
    {
      headerName: 'Scene',
      field: 'scene',
      width: 128,
      filter: true,
      tooltipField: 'Filter and Sort by Scene name'
    },
    // Lighting is Demo only so far
    //{ headerName: 'Lighting', field: 'illumination', width: 100, filter: true },

    {
      headerName: 'Lens Used',
      field: 'lens',
      filter: true,
      tooltipField: 'Filter and sort by lens'
    },
    {
      headerName: 'Sensor',
      field: 'sensor',
      filter: true,
      tooltipField: 'Filter and sort by sensor'
    },
    // Hidden fields for addtional info
    { headerName: 'Preview', field: 'preview', hide: true },
    { headerName: 'jpegName', field: 'jpegName', hide: true },
    { headerName: 'sensorRawFile', field: 'sensorRawFile', hide: true },
    { headerName: 'sensorRawName', field: 'sensorRawName', hide: true },
    { headerName: 'oiName', field: 'oiName', hide: true },
    { headerName: 'AE-Method', field: 'aeMethod', hide: true },
    { headerName: 'ExposureTime', field: 'eTime', hide: true },
    { headerName: 'Pixel', field: 'pixel', hide: true },
    { headerName: 'Burst Preview', field: 'burstPreview', hide: true },
    { headerName: 'Bracket Preview', field: 'bracketPreview', hide: true },
    { headerName: 'YOLO Preview', field: 'YOLOPreview', hide: true },
    { headerName: 'YOLO Burst Preview', field: 'YOLOBurstPreview', hide: true },
    {
      headerName: 'YOLO Bracket Preview',
      field: 'YOLOBracketPreview',
      hide: true
    }
    // We don't currently provide the Raw for burst & bracket
    // TBD: Other burst & bracket frame numbers &/or f-Stops
  ])

  const fSlider = useRef([]) // This will be the preview image element & Slider
  const selectedRow = useRef([]) // for use later when we need to download
  const pI = useRef('')
  const currentSensor = useRef('')
  const [userSensor, setUserSensor] = useState('')


  // This is where we can add ability to call our compiled Matlab code
  const btnComputeListener = useCallback(event => {
    // test code for now

    // get content from the sensor editor to use for this
    //var ourEdit = document.getElementById('sensorID')
    //setUserSensor(ourEdit.get);

    const requestOptions = {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sensor: userSensorContent,
        oiFile: selectedRow.current.oiName,
        name: selectedRow.current.name
      })
    }

    var responseText = '';
    // Our test server
    var testServer = 'http://seedling:3001'

    fetch(testServer + '/compute', requestOptions)
      .then(response => response.text())
      .then(rText => console.log("Response is: " + rText))
      // show our re-calced image 
      .then(useFile => {
        var cI = document.getElementById('computedImage');
        // we actually don't use the filename yet
        cI.src = 'http://seedling:3001' + '/images/sensorImage.png'})

  }, [])



  // When the user changes the type of exposure calculation
  // we change the preview and possibly also the number of frames
  const btnExposureListener = useCallback(event => {
    pI.current = document.getElementById('previewImage')
    fSlider.current = document.getElementById('frameSlider')
    var ourButton = document.getElementById(event.target.id)

    // need to also change the DL file(s)
    switch (event.target.id) {
      case 'buttonAE':
        // put back the default preview
        if (YOLOMode.current) {
          pI.current.src = selectedRow.current.YOLOPreview
        } else {
          pI.current.src = selectedRow.current.preview
        }
        selectedImage.rgbData = selectedRow.current.previewImage
        setValue(1) // sets the number of frames slider
        captureType.current = 'single'
        break

      case 'buttonBurst':
        // show the burst image
        if (YOLOMode.current) {
          pI.current.src = selectedRow.current.YOLOBurstPreview
        } else {
          pI.current.src = selectedRow.current.burstPreview
        }
        selectedImage.rgbData = selectedRow.current.burstPreview
        setValue(5)
        captureType.current = 'burst'
        break

      case 'buttonBracket':
        // show the bracketed image
        if (YOLOMode.current) {
          pI.current.src = selectedRow.current.YOLOBracketPreview
        } else {
          pI.current.src = selectedRow.current.bracketPreview
        }
        selectedImage.rgbData = selectedRow.current.bracketPreview
        setValue(3)
        captureType.current = 'bracket'
        break
      case 'buttonYOLO':
        // Show /toggle YOLO annotations
        if (YOLOMode.current === false) {
          YOLOMode.current = true
          ourButton.innerHTML = 'Hide YOLO'
          switch (captureType.current) {
            case 'single':
              pI.current.src = selectedRow.current.YOLOPreview
              break
            case 'burst':
              pI.current.src = selectedRow.current.YOLOBurstPreview
              break
            case 'bracket':
              pI.current.src = selectedRow.current.YOLOBracketPreview
              break
            default:
              // Shouldn't happen
              break
          }
        } else {
          YOLOMode.current = false
          ourButton.innerHTML = 'Show YOLO'
          switch (captureType.current) {
            case 'single':
              pI.current.src = selectedRow.current.preview
              break
            case 'burst':
              pI.current.src = selectedRow.current.burstPreview
              break
            case 'bracket':
              pI.current.src = selectedRow.current.bracketPreview
              break
            default:
              // shouldn't get here
              break
          }
        }
        break
      default:
        // Shouldn't happen
        break
    }
  }, [])

  const rowClickedListener = useCallback(event => {
    //console.log('Row Clicked: \n', event)
    setValue(1) // always start with 1 frame AE, at least for now
    selectedRow.current = event.data
    pI.current = document.getElementById('previewImage')

    // load the selected sensor in case the user wants
    // to modify its parameters and recompute
    var factorySensorFile = selectedRow.current.sensorObject.sensorFileName
    var dataPrepSensorFile = factorySensorFile.replace('.json', '-Baseline.json');
    // Fetch Function   
    fetch("/sensors/" + dataPrepSensorFile).then(
      function (res) {
        return res.json()
      }).then(function (data) {
        // store Data in State Data Variable
        setContent({
          json: data,
          text: undefined
        })
      }).catch(
        function (err) {
          console.log(err, ' error')
        }
      )

    // Set the baseline user sensor
    setUserSensor(currentSensor.current);

    console.log(currentSensor.current)

    // We should clearly add a 'setter' to the Mode
    YOLOMode.current = false
    var ourButton = document.getElementById('buttonYOLO')
    ourButton.innerHTML = 'Show YOLO'

    pI.current.src = selectedRow.current.preview
    selectedImage.rgbData = selectedRow.current.previewImage

    // Change preview caption
    var pCaption, eTime, aeMethod
    pCaption = document.getElementById('previewCaption')
    pCaption.textContent = selectedRow.current.jpegFile

    // Update Image property table
    eTime = document.getElementById('eTime')
    var exposureTime = selectedRow.current.eTime
    eTime.textContent = exposureTime.toFixed(4) + ' seconds'
    aeMethod = document.getElementById('aeMethod')
    aeMethod.textContent = selectedRow.current.aeMethod

    // Update Pixel property table
    var pWidth, pHeight, pConversionGain, pVoltageSwing
    pWidth = document.getElementById('pWidth')
    pHeight = document.getElementById('pHeight')
    pWidth.textContent =
      (event.data.pixel.width * 1000000).toFixed(2) + ' microns'
    pHeight.textContent =
      (event.data.pixel.height * 1000000).toFixed(2) + ' microns'
    pConversionGain = document.getElementById('pConversionGain')
    pVoltageSwing = document.getElementById('pVoltageSwing')
    pConversionGain.textContent = selectedRow.current.pixel.conversionGain
    pVoltageSwing.textContent = selectedRow.current.pixel.voltageSwing
  }, [])

  // Handle download buttons
  const buttonDownload = useCallback(event => {
    let dlName = ''
    let dlPath = ''
    if (selectedRow.current === undefined) {
      window.alert('You need to select a sensor image first.')
      return
    }
    // Need to figure out which scene & which file
    // TBD: Add support for DL burst/bracket variants
    switch (event.currentTarget.id) {
      case 'dlSensorVolts':
        dlPath = selectedRow.current.sensorRawFile
        dlName = selectedRow.current.sensorRawName
        break
      case 'dlIPRGB':
        dlPath = selectedRow.current.preview
        dlName = selectedRow.current.jpegFile
        break
      case 'dlOI':
        // Some OI may be too large, but so far so good
        dlPath = oiDir + selectedRow.current.oiName
        dlName = selectedRow.current.oiName
        break
      default:
      // Nothing
    }
    console.log(process.env.PUBLIC_URL)
    console.log(dlPath)
    console.log(dlName)
    saveAs(process.env.PUBLIC_URL + dlPath, dlName)
  }, [])

  // for now open the preview image in a new window
  // might want to do more interesting things later
  const previewClick = useCallback(event => {
    var ourImage = document.getElementById('previewImage')
    window.open(ourImage.src)
  }, [])

  const expMarks = [
    {
      value: 1,
      label: '1'
    },
    {
      value: 3,
      label: '3'
    },
    {
      value: 5,
      label: '5'
    }
  ]

  const [value, setValue] = useState(1)

  const changeValue = (event, value) => {
    setValue(value)
  }

  const [showEditor, setShowEditor] = useState(true);
  const [readOnly, setReadOnly] = useState(false);

  // JSX (e.g. HTML +) STARTS HERE
  // -----------------------------

  return (
    <CContainer fluid>

      {/* Row 1 is our Header & README*/}
      <CRow className='justify-content-start'>
        <CCol xs={1}>
          <CImage width='100' src={SU_Logo}></CImage>
        </CCol>
        <CCol xs={4}>
          <CImage width='300' src='/glyphs/Vista_Lab_Logo.png'></CImage>
          <h2>ISET Camera Simulator</h2>
        </CCol>
        <CCol xs={7}>
          <p>
            <br></br>Select a scene, a lens, and a sensor, to get a
            highly-accurate simulated image. From there you can download the
            Voltage response that can be used to evaluate your own image
            processing pipeline, or a JPEG with a simple rendering, or the
            original optical image if you want to do further analysis on your
            own.
          </p>
        </CCol>
      </CRow>

      {/* Try Row 2 as everything else */}
      <CRow className='align-items-start'>
        {/* First column is grid + Proper */}
        <CCol xs={7} className='align-items-start'>
          {/* First row is grid */}
          <CRow>
            <div
              className='ag-theme-alpine'
              style={{ width: 900, height: 400 }}
            >
              <AgGridReact
                ref={gridRef} // Ref for accessing Grid's API
                rowData={rowData} // Row Data for Rows
                columnDefs={columnDefs} // Column Defs for Columns
                animateRows={true} // Optional - set to 'true' to have rows animate when sorted
                rowSelection='single' // Options - allows click selection of rows
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
                    <CTableHeaderCell scope='col'>
                      <h5>Image Properties:</h5>
                    </CTableHeaderCell>
                    <CTableHeaderCell scope='col'>
                      <h5>Value:</h5>
                    </CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody id='imageProps'>
                  <CTableRow color='primary'>
                    <CTableDataCell>Expsoure:</CTableDataCell>
                    <CTableDataCell id='eTime'>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='secondary'>
                    <CTableDataCell>AE Method</CTableDataCell>
                    <CTableDataCell id='aeMethod'>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='primary'>
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='secondary'>
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='primary'>
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
                    <CTableHeaderCell scope='col'>
                      <h5>Pixel Properties:</h5>
                    </CTableHeaderCell>
                    <CTableHeaderCell scope='col'>
                      <h5>Value:</h5>
                    </CTableHeaderCell>
                  </CTableRow>
                </CTableHead>
                <CTableBody id='pixelProps'>
                  <CTableRow color='primary'>
                    <CTableDataCell>Width:</CTableDataCell>
                    <CTableDataCell id='pWidth'>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='secondary'>
                    <CTableDataCell>Height:</CTableDataCell>
                    <CTableDataCell id='pHeight'>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='primary'>
                    <CTableDataCell>Conversion Gain:</CTableDataCell>
                    <CTableDataCell id='pConversionGain'>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='secondary'>
                    <CTableDataCell>Voltage Swing:</CTableDataCell>
                    <CTableDataCell id='pVoltageSwing'>...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='primary'>
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
              <div className="App">
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
                    <h2>Sensor Editor:

                      <CButton onClick={btnComputeListener}>
                        Re-compute</CButton></h2>

                    <div className="my-editor">
                      <SvelteJSONEditor
                        id='sensorID'
                        ref={sensorEditor}
                        content={content}
                        readOnly={false}
                        onChange={setContent}
                      />
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
            <CCol> {/* put re-computed preview here for now*/}
              <CImage
                id='computedImage'
                ref={computedEl}
                rounded
                thumbnail
                src={computedImage}
              />
            </CCol>
          </CRow>
        </CCol>
        <CCol xs={4}>
          <CRow className='align-items-center'>
            <CButton
              style={{ background: 'none', border: 'none' }}
              onClick={previewClick}
            >
              <CImage
                id='previewImage'
                ref={imgEl}
                rounded
                thumbnail
                src={previewImage}
              />
            </CButton>
          </CRow>
          <CRow className='align-items-center'>
            <h5>Preview of Selected Sensor Image:</h5>
            <p id='previewCaption'> No image selected </p>
          </CRow>
          <CRow>
            <h5>Exposure Options:</h5>
            <CButtonGroup role='group' aria-label='Exposure Options:'>
              <CTooltip content='Simple Auto-Exposure'>
                <CButton
                  variant='outline'
                  data-tip='Simple Auto-Exposure'
                  color='primary'
                  id='buttonAE'
                  onClick={btnExposureListener}
                >
                  {' '}
                  AE
                </CButton>
              </CTooltip>
              <CTooltip content='Multi-frame Burst'>
                <CButton
                  variant='outline'
                  color='primary'
                  id='buttonBurst'
                  onClick={btnExposureListener}
                >
                  {' '}
                  Burst
                </CButton>
              </CTooltip>
              <CTooltip content='Multi-frame Bracket'>
                <CButton
                  variant='outline'
                  color='primary'
                  id='buttonBracket'
                  onClick={btnExposureListener}
                >
                  {' '}
                  Bracket
                </CButton>
              </CTooltip>
            </CButtonGroup>
          </CRow>
          <CRow>
            <h5>Frames Captured:</h5>
            <Box>
              <Slider
                id='frameSlider'
                ref={expSlider}
                aria-label='Number of Frames'
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
              <CTooltip content='This is the full sensor object, including its response in volts.'>
                <CButton
                  id='dlSensorVolts'
                  variant='outline'
                  onClick={buttonDownload}
                >
                  Sensor Image
                </CButton>
              </CTooltip>
              <CTooltip content='This is an example RGB result after processing the sensor data.'>
                <CButton
                  id='dlIPRGB'
                  variant='outline'
                  onClick={buttonDownload}
                >
                  Processed Image
                </CButton>
              </CTooltip>
              <CTooltip content='This is the irradiance on the film plane of the scene viewed throug the lens.'>
                <CButton id='dlOI' variant='outline' onClick={buttonDownload}>
                  Optical Image
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
              id='buttonYOLO'
              variant='outline'
              onClick={btnExposureListener}
            >
              Show YOLO
            </CButton>
            <CButton
              id='buttonGT'
              variant='outline'
              disabled
              onClick={btnExposureListener}
            >
              Ground Truth
            </CButton>
          </CButtonGroup>
          <h5>Compute:</h5>
          <CButton
            id='buttonCompute'
            variant='outline'
            onClick={btnComputeListener}
          >
            TEST Only
          </CButton>
        </CCol>
      </CRow>

      <CFooter>
        <div>
          <span>&copy; 2022 VistaLab, Stanford University</span>
        </div>
        <div>
          <span>...</span>
          <CLink href='https://vistalab.stanford.edu'>VistaLab Team</CLink>
        </div>
      </CFooter>
    </CContainer>
  )
}

export { App, updateUserSensor }
