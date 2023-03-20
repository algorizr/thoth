import { z } from 'zod';
import { SubmitHandler, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

type FormInputLabel = {
  name: string;
  style?: string;
};

export enum FormInputType {
  TextInput = 'text',
  EmailInput = 'email',
  PasswordInput = 'password',
  NumberInput = 'number',
  RelationInput = 'relation',
  DateTimeInput = 'datetime-local',
  DateInput = 'date',
  CheckboxInput = 'checkbox',
}

type FormInput = {
  type: FormInputType;
  name: string;
  isVisible: boolean;
  style?: string;
  errorStyle?: string;
  defaultValue?: string | number | boolean | { [x: string]: any };
  placeholder?: string;
};

type FormElement = {
  style?: string;
  formInputLabel?: FormInputLabel;
  formInput: FormInput;
};

type FormButton = {
  name: string;
  style?: string;
};

type FormProps = {
  formFunc: (data: any) => Promise<Response>;
  formStyle?: string;
  formElementStyle?: string;
  formInputStyle?: string;
  formInputErrorStyle?: string;
  formInputLabelStyle?: string;
  formElements: FormElement[];
  formButton: FormButton;
  formValidationSchema: z.AnyZodObject;
  handleResponse?: (response: any) => void;
};

const Form = ({
  formFunc,
  formElements,
  formButton,
  formValidationSchema,
  formStyle,
  formElementStyle,
  formInputStyle,
  formInputErrorStyle,
  formInputLabelStyle,
  handleResponse,
}: FormProps) => {
  type FormSchemaType = z.infer<typeof formValidationSchema>;
  const formDefaultValues: { [key: string]: any } = {};

  formElements.map((formElement) => {
    const formInput = formElement.formInput;
    if (formInput.defaultValue)
      formDefaultValues[formInput.name] = formInput.defaultValue;
  });

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormSchemaType>({
    resolver: zodResolver(formValidationSchema),
  });

  const onSubmit: SubmitHandler<FormSchemaType> = async (formData: any) => {
    try {
      const response = await formFunc({ ...formData, ...formDefaultValues });

      const data = await response.json();

      if (response.ok || response.status == 201) {
        if (handleResponse) handleResponse(data);
      } else {
        console.log(data);
      }
    } catch (error) {
      console.log(error);
    }
  };

  return (
    <form className={formStyle} onSubmit={handleSubmit(onSubmit)}>
      {formElements.map((formElement, idx) => {
        const formInput = formElement.formInput;
        const formLabel = formElement?.formInputLabel;
        if (formInput.type !== FormInputType.RelationInput)
          return (
            <div
              hidden={!formInput.isVisible}
              key={idx}
              className={
                formElement.style ? formElement.style : formElementStyle
              }
            >
              {formLabel && (
                <label
                  htmlFor={formInput.name}
                  className={
                    formLabel.style ? formLabel.style : formInputLabelStyle
                  }
                >
                  {formLabel.name}
                </label>
              )}
              <input
                id={formInput.name}
                type={formInput.type}
                className={formInput.style ? formInput.style : formInputStyle}
                placeholder={formInput.placeholder}
                {...register(formInput.name)}
              />
              {errors[formInput.name] && (
                <span
                  className={
                    formInput.errorStyle
                      ? formInput.errorStyle
                      : formInputErrorStyle
                  }
                >
                  {errors[formInput.name]?.message?.toString()}
                </span>
              )}
            </div>
          );
      })}
      <button className={formButton.style} disabled={isSubmitting}>
        {formButton.name}
      </button>
    </form>
  );
};

export default Form;
