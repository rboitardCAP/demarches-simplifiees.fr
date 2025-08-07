import React, { useState, useEffect, CSSProperties } from 'react';
import { useDispatchChangeEvent } from '~/components/react-aria/hooks.ts';
import { CheckboxProps, CheckboxGroupProps } from '~/components/react-aria/props.ts';

/**
 * Checkbox component.
 * @param {CheckboxProps} props - The properties for the checkbox.
 * @returns {JSX.Element} The rendered checkbox component.
 */
export function Checkbox({ key, id, label, checked, onChange, inputRef }: CheckboxProps) {
  return (
    <div className="fr-checkbox-group__item">
      <input
        key={key}
        type="checkbox"
        ref={inputRef}               // Attach the ref to the input element
        id={id}
        checked={checked}
        onChange={onChange}
        className="fr-input"
      />
      <label htmlFor={id} className="fr-label">
        {label}
      </label>
    </div>
  );
}

/**
 * Custom hook to manage checkbox group state.
 * @param {string[]} initialSelectedItems - The initial selected items.
 * @returns {{ selectedItems: string[], handleCheckboxChange: (event: React.ChangeEvent<HTMLInputElement>) => void }} The selected items and change handler.
 */
export function useCheckboxGroup(initialSelectedItems: string[]) {
  // Ensure selectedItems is always initialized as an array
  const [selectedItems, setSelectedItems] = useState<string[]>(initialSelectedItems || []);

  // Handle change event for checkboxes
  const handleCheckboxChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { id, checked } = event.target;
    const newSelectedItems = checked ? [...selectedItems, id] : selectedItems.filter((item) => item !== id);
    setSelectedItems(newSelectedItems);
  };

  // Update selected items when initial items change
  useEffect(() => {
    setSelectedItems(initialSelectedItems || []);
  }, [initialSelectedItems]);

  return {
    selectedItems,
    handleCheckboxChange,
  };
}

/**
 * Checkbox group component.
 * @param {CheckboxGroupProps} props - The properties for the checkbox group.
 * @returns {JSX.Element} The rendered checkbox group component.
 */
export function CheckboxGroup({ inputName, itemSet, initialSelectedItems, groupLabel, alignHorizontally=true }: CheckboxGroupProps) {
  const { inputRef, dispatch } = useDispatchChangeEvent(); // Hook to dispatch change events
  const { selectedItems, handleCheckboxChange } = useCheckboxGroup(initialSelectedItems); // Custom hook for checkbox group state

  // Dispatch change event when selected items change
  useEffect(() => {
    dispatch();
  }, [selectedItems, dispatch]);

  // CSS for aligning checkboxes horizontally if required
  const horizontalAlignStyle: CSSProperties = alignHorizontally ? {
    display: "flex",
    flexWrap: "wrap",
    gap: "0.5rem 2rem"
  } : {};

  return (
    <div aria-labelledby="checkbox-group-label">
      <label id="checkbox-group-label" className="fr-mt-1w">
        {groupLabel}
      </label>

      <div className="fr-checkbox-group fr-checkbox-group--sm" style={horizontalAlignStyle}>
        {Object.entries(itemSet).map(([key, label]) => (
          <Checkbox
            key={key}
            id={key}
            label={label}
            checked={selectedItems.includes(key)}
            onChange={handleCheckboxChange}
            inputRef={inputRef}
          />
        ))}
      </div>

      <span ref={inputRef}>
        {selectedItems.map((item, index) => (
          <input
            key={index}
            type="hidden"
            name={inputName}
            value={item}
          />
        ))}
      </span>
    </div>
  );
}
