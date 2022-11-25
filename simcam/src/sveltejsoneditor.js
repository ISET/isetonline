import { JSONEditor } from "vanilla-jsoneditor";
import { useEffect, useRef } from "react";
import './App';
import { updateUserSensor } from "./App";
import "./sveltejsoneditor.css";

let content = {
  json: {
    name: "Select image to see sensor data"
  },
  text: undefined
  }

export default function SvelteJSONEditor(props) {
  const refContainer = useRef(null);
  const refEditor = useRef(null);

  useEffect(() => {
    // create editor
    console.log("create editor", refContainer.current);
    refEditor.current = new JSONEditor({
      target: refContainer.current,
      props: {content,
        onChange: (updatedContent, previousContent, { contentErrors, patchResult }) => {
        // content is an object { json: JSONValue } | { text: string }
        console.log('onChange', { updatedContent, previousContent, contentErrors, patchResult })
        content = updatedContent }
    }});

    return () => {
      // destroy editor
      if (refEditor.current) {
        console.log("destroy editor");
        refEditor.current.destroy();
        refEditor.current = null;
      }
    };
  }, []);

  // update props
  useEffect(() => {
    if (refEditor.current) {
      console.log("update props", props);
      updateUserSensor(props.content.json);
      refEditor.current.updateProps(props);
      
    }
  }, [props]);

  return <div className="svelte-jsoneditor-react" ref={refContainer}></div>;
}