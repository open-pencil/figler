defmodule FigKiwi.NativeSceneGenerator do
  @moduledoc false

  alias KiwiCodec.Schema
  alias KiwiCodec.Schema.Definition

  @primitive_skip %{
    "bool" => "decoder.read_bool()?;",
    "byte" => "decoder.read_byte()?;",
    "float" => "decoder.read_var_float_value()?;",
    "int" => "decoder.read_var_int()?;",
    "int64" => "decoder.read_var_int64()?;",
    "string" => "decoder.skip_string()?;",
    "uint" => "decoder.read_var_uint()?;",
    "uint64" => "decoder.read_var_uint64()?;"
  }

  def render(%Schema{} = schema) do
    definition_map = Map.new(schema.definitions, &{&1.name, &1})

    [summary_struct(), node_type_name(definition_map)] ++
      Enum.map(schema.definitions, &skip_definition(&1, definition_map)) ++
      scene_summary(definition_map)
  end

  defp summary_struct do
    """
    #[derive(rustler::NifMap)]
    pub struct SceneSummary {
        node_count: usize,
        parented_count: usize,
        root_count: usize,
        type_counts: Vec<(String, usize)>,
    }
    """
  end

  defp node_type_name(definition_map) do
    arms =
      definition_map
      |> Map.fetch!("NodeType")
      |> then(& &1.fields)
      |> Enum.map_join("\n", fn field ->
        "#{field.value} => \"#{Macro.underscore(field.name)}\","
      end)

    """
    fn scene_node_type_name(value: u32) -> &'static str {
        match value {
    #{indent(arms, 8)}
            _ => "unknown",
        }
    }
    """
  end

  defp skip_definition(%Definition{kind: :enum, name: name}, _definition_map) do
    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
        decoder.read_var_uint()?;
        Ok(())
    }
    """
  end

  defp skip_definition(%Definition{kind: :struct, name: name, fields: fields}, definition_map) do
    body = Enum.map_join(fields, "\n", &skip_field(&1, definition_map))

    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
    #{indent(body, 4)}
        Ok(())
    }
    """
  end

  defp skip_definition(%Definition{kind: :message, name: name, fields: fields}, definition_map) do
    arms = Enum.map_join(fields, "\n", &skip_message_arm(&1, definition_map))

    """
    fn skip_#{rust_ident(name)}_from_decoder(decoder: &mut Decoder<'_>) -> NifResult<()> {
        loop {
            match decoder.read_var_uint()? {
                0 => break,
    #{indent(arms, 12)}
                field => return Err(Error::Term(Box::new(format!("unknown field {} while skipping #{name}", field)))),
            }
        }
        Ok(())
    }
    """
  end

  defp scene_summary(definition_map) do
    message_arms =
      definition_map
      |> Map.fetch!("Message")
      |> then(& &1.fields)
      |> Enum.reject(&(&1.value == 4))
      |> Enum.map_join("\n", &skip_message_arm(&1, definition_map))

    node_change_arms =
      definition_map
      |> Map.fetch!("NodeChange")
      |> then(& &1.fields)
      |> Enum.reject(&(&1.value in [1, 3, 4, 5]))
      |> Enum.map_join("\n", &skip_message_arm(&1, definition_map))

    [
      """
      #[rustler::nif(schedule = "DirtyCpu")]
      pub fn decode_scene_summary<'a>(env: Env<'a>, bytes: Binary<'a>) -> NifResult<Term<'a>> {
          let mut decoder = Decoder::new(bytes.as_slice());
          let mut node_count: usize = 0;
          let mut parented_count: usize = 0;
          let mut type_counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();

          decode_scene_message_from_decoder(&mut decoder, &mut node_count, &mut parented_count, &mut type_counts)?;
          decoder.finish()?;
          let mut type_counts = type_counts.into_iter().collect::<Vec<_>>();
          type_counts.sort_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));

          Ok(SceneSummary {
              node_count,
              parented_count,
              root_count: node_count.saturating_sub(parented_count),
              type_counts,
          }.encode(env))
      }
      """,
      """
      fn decode_scene_message_from_decoder(
          decoder: &mut Decoder<'_>,
          node_count: &mut usize,
          parented_count: &mut usize,
          type_counts: &mut std::collections::HashMap<String, usize>,
      ) -> NifResult<()> {
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
      #{indent(message_arms, 12)}
                  4 => {
                      let len = decoder.read_var_uint()? as usize;
                      for _ in 0..len {
                          decode_scene_node_change_from_decoder(decoder, node_count, parented_count, type_counts)?;
                      }
                  },
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding scene summary", field)))),
              }
          }
          Ok(())
      }
      """,
      """
      fn decode_scene_node_change_from_decoder(
          decoder: &mut Decoder<'_>,
          node_count: &mut usize,
          parented_count: &mut usize,
          type_counts: &mut std::collections::HashMap<String, usize>,
      ) -> NifResult<()> {
          *node_count += 1;
          loop {
              match decoder.read_var_uint()? {
                  0 => break,
                  1 => skip_guid_from_decoder(decoder)?,
                  3 => {
                      skip_parent_index_from_decoder(decoder)?;
                      *parented_count += 1;
                  },
                  4 => {
                      let value = decoder.read_var_uint()?;
                      let name = scene_node_type_name(value).to_string();
                      *type_counts.entry(name).or_insert(0) += 1;
                  },
                  5 => decoder.skip_string()?,
      #{indent(node_change_arms, 12)}
                  field => return Err(Error::Term(Box::new(format!("unknown field {} while decoding scene node", field)))),
              }
          }
          Ok(())
      }
      """
    ]
  end

  defp skip_message_arm(field, definition_map) do
    "#{field.value} => { #{skip_field(field, definition_map)} },"
  end

  defp skip_field(%{array?: true, type: "byte"}, _definition_map) do
    "decoder.skip_byte_array()?;"
  end

  defp skip_field(%{array?: true} = field, definition_map) do
    inner = skip_field(%{field | array?: false}, definition_map)

    """
    {
        let len = decoder.read_var_uint()? as usize;
        for _ in 0..len {
    #{indent(inner, 8)}
        }
    }
    """
  end

  defp skip_field(%{type: type}, definition_map) do
    cond do
      primitive = @primitive_skip[type] ->
        primitive

      Map.has_key?(definition_map, type) ->
        "skip_#{rust_ident(type)}_from_decoder(decoder)?;"
    end
  end

  defp rust_ident(name) do
    name
    |> Macro.underscore()
    |> String.replace(~r/[^a-zA-Z0-9_]/, "_")
  end

  defp indent(text, spaces) do
    padding = String.duplicate(" ", spaces)

    text
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map_join("\n", &(padding <> &1))
  end
end
