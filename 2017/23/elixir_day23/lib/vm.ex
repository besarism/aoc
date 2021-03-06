defmodule ElixirDay23.VM do
  alias ElixirDay23.{VM, PrimeFactors}

  defstruct [
    :memory,
    :pc,
    :registers,
    :mul_count,
    :halted
  ]

  def init_registers() do
    Enum.to_list(?a..?h)
    |> List.to_string()
    |> String.graphemes()
    |> Map.new(fn letter -> {letter, 0} end)
  end

  def parse(filename) do
    File.stream!(filename)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.split/1)
    |> Enum.map(fn list ->
      list |> Enum.map(&try_parse_int/1)
    end)
  end

  def try_parse_int(string) do
    case Integer.parse(string) do
      :error -> string
      {num, _} -> num
    end
  end

  def new(filename) do
    %VM{
      memory: parse(filename),
      pc: 0,
      registers: init_registers(),
      mul_count: 0,
      halted: false
    }
  end

  def turn_off_debug(vm) do
    registers = Map.put(vm.registers, "a", 1)
    %{vm | registers: registers}
  end

  def lookup(_, arg) when is_integer(arg), do: arg

  def lookup(vm, arg) when is_binary(arg) do
    vm.registers |> Map.get(arg)
  end

  def execute_until_halt(vm) do
    vm = execute_step(vm)

    if vm.halted == true do
      vm
    else
      execute_until_halt(vm)
    end
  end

  def execute_step(%VM{memory: memory, pc: pc} = vm) do
    instruction = memory |> Enum.at(pc)

    [
      vm.registers["a"],
      vm.registers["b"],
      vm.registers["c"],
      vm.registers["d"],
      vm.registers["e"],
      vm.registers["f"],
      vm.registers["g"],
      vm.registers["h"]
    ]
    |> IO.inspect()

    [pc + 1 | instruction] |> IO.inspect()
    IO.puts("")

    do_execute_step(vm, instruction)
  end

  @doc """
  Starting at instruction 9, we have two loops:

  for d in range(2, b):
    for e in range(2, b):
      if d*e == b:
        f = 0

  Essentially, it's just checking if b is prime.  If not prime,
  set f to 0.
  """
  def do_execute_step(%VM{pc: 9, registers: r} = vm, _instruction) do
    new_f = if not PrimeFactors.is_prime?(r["b"]), do: 0, else: 1

    new_reg =
      vm.registers
      |> Map.put("f", new_f)

    %{vm | registers: new_reg, pc: 24}
  end

  def do_execute_step(vm, ["set", arg1, arg2]) do
    registers = Map.put(vm.registers, arg1, lookup(vm, arg2))
    %{vm | registers: registers, pc: vm.pc + 1}
  end

  def do_execute_step(vm, ["sub", arg1, arg2]) do
    registers = Map.update!(vm.registers, arg1, fn x -> x - lookup(vm, arg2) end)
    %{vm | registers: registers, pc: vm.pc + 1}
  end

  def do_execute_step(vm, ["mul", arg1, arg2]) do
    registers = Map.update!(vm.registers, arg1, fn x -> x * lookup(vm, arg2) end)
    %{vm | registers: registers, pc: vm.pc + 1, mul_count: vm.mul_count + 1}
  end

  def do_execute_step(vm, ["jnz", arg1, arg2]) do
    val1 = lookup(vm, arg1)
    val2 = lookup(vm, arg2)

    if val1 != 0 do
      %{vm | pc: vm.pc + val2}
    else
      %{vm | pc: vm.pc + 1}
    end
  end

  # Nil instruction = halted
  def do_execute_step(vm, nil) do
    %{vm | halted: true}
  end
end
