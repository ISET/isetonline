import React, { useState, useRef, useCallback } from 'react'
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

// Additional components
import { saveAs } from 'file-saver'
// import { PopupComponent } from 'ag-grid-community'

// Load our rendered sensor images
// They are located in sub-folders under /public
let dataDir = './data/'
let imageDir = '/images/' // Should use /public by default?
let oiDir = '/oi/'

let imageData = require(dataDir + 'metadata.json')

let testImage = 'http://stanford.edu/favicon.ico'
let previewImage = testImage // imageDir + imageData[0].jpegName

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

      // Used to set the file for the preview window
      preview: imageDir + imageData[ii].jpegName,

      // And for alternate versions
      // Right now just burst & bracket
      // We should probably have a more general
      // "variants" based scheme
      burstPreview: imageDir + imageData[ii].burstJPEGName,
      bracketPreview: imageDir + imageData[ii].bracketJPEGName,

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

const App = () => {
  const gridRef = useRef()
  const expSlider = useRef()

  // let the grid know which columns and what data to use
  const [rowData] = useState(rows)

  // Each Column Definition results in one Column.
  const [columnDefs] = useState([
    {
      headerName: 'Thumbnail',
      width: 128,
      field: 'thumbnail',
<<<<<<< HEAD
      cellRenderer: ImageRenderer
    },
    { headerName: 'Scene', field: 'scene', width: 128, filter: true },
    // Lighting is Demo only so far
    { headerName: 'Lighting', field: 'illumination', width: 100, filter: true },

    { headerName: 'Lens Used', field: 'lens', filter: true },
=======
      cellRenderer: ImageRenderer,
      tooltipField: 'Scene Thumbnail',
    },
    { headerName: 'Scene', field: 'scene', width: 128, filter: true,
      tooltipField: 'Filter and Sort by Scene name' },
    // Lighting is Demo only so far
    { headerName: 'Lighting', field: 'illumination', width: 100, filter: true },

    { headerName: 'Lens Used', field: 'lens', filter: true,
    tooltipField: 'Filter and sort by lens',
    },
>>>>>>> parent of 7dcf406 (Add static site files)
    { headerName: 'Sensor', field: 'sensor', filter: true },
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
    { headerName: 'Bracket Preview', field: 'bracketPreview', hide: true }
    // We don't currently provide the Raw for burst & bracket
    // TBD: Other burst & bracket frame numbers &/or f-Stops
  ])

  const fSlider = useRef([]) // This will be the preview image element & Slider
  const selectedRow = useRef([]) // for use later when we need to download
  const pI = useRef('')

  // When the user changes the type of exposure calculation
  // we change the preview and possibly also the number of frames
  const btnExposureListener = useCallback(event => {
    pI.current = document.getElementById('previewImage')
    fSlider.current = document.getElementById('frameSlider')

    // need to also change the DL file(s)
    switch (event.target.id) {
      case 'buttonAE':
        // put back the default preview
        pI.current.src = selectedRow.current.preview
        selectedImage.rgbData = selectedRow.current.previewImage
        setValue(1) // sets the number of frames slider
        break

      case 'buttonBurst':
        // show the burst image
        pI.current.src = selectedRow.current.burstPreview
        selectedImage.rgbData = selectedRow.current.burstPreview
        setValue(5)
        break

      case 'buttonBracket':
        // show the bracketed image
        pI.current.src = selectedRow.current.bracketPreview
        selectedImage.rgbData = selectedRow.current.bracketPreview
        setValue(3)
        break
      default:
        // Shouldn't happen
        break
    }
  }, [])

  const rowClickedListener = useCallback(event => {
    //console.log('Row Clicked: \n', event)
    setValue(1) // always start with 1 frame AE, at least for now
    pI.current = document.getElementById('previewImage')

    pI.current.src = event.data.preview
    selectedImage.rgbData = event.data.previewImage
    selectedRow.current = event.data

    // Change preview caption
    var pCaption, eTime, aeMethod
    pCaption = document.getElementById('previewCaption')
    pCaption.textContent = event.data.jpegFile

    // Update Image property table
    eTime = document.getElementById('eTime')
    var exposureTime = event.data.eTime
    eTime.textContent = exposureTime.toFixed(4) + ' seconds'
    aeMethod = document.getElementById('aeMethod')
    aeMethod.textContent = event.data.aeMethod

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
    pConversionGain.textContent = event.data.pixel.conversionGain
    pVoltageSwing.textContent = event.data.pixel.voltageSwing

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

  // JSX (e.g. HTML +) STARTS HERE
  // -----------------------------

  return (
    <CContainer fluid>
      {/* Row 1 is our Header & README*/}
      <CRow className="justify-content-start">
        <CCol xs={1}>
          <CImage width='100' src='/glyphs/Stanford_Logo.png'></CImage>
        </CCol>
        <CCol xs={4}>
          <CImage  width='300' src='/glyphs/Vista_Lab_Logo.png'></CImage>
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
            {/* For now next row is Pixel props */}
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
                    <CTableDataCell id="pVoltageSwing">...</CTableDataCell>
                  </CTableRow>
                  <CTableRow color='primary'>
                    <CTableDataCell>...</CTableDataCell>
                    <CTableDataCell>...</CTableDataCell>
                  </CTableRow>
                </CTableBody>
              </CTable>
            </CCol>
          </CRow>
        </CCol>
        <CCol xs={4}>
          <CRow className='align-items-center'>
            <CImage id='previewImage' rounded thumbnail src={previewImage} />
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
          {/* Put buttons here? */}
          <CButton>'TBD'</CButton>
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

export default App
