import std/options

type Queue*[T] = object
  data: seq[T]
  tail: int
  len: int

func newQueue*[T](cap: int): Queue[T] =
  result.data.setLen(cap)

func last*[T](queue: Queue[T]): lent T =
  queue.data[queue.tail]

func first*[T](queue: Queue[T]): lent T =
  assert queue.len > 0
  queue.data[(queue.tail + queue.len - 1) mod queue.data.len]

func add*[T](queue: var Queue[T], v: sink T) =
  if queue.tail == 0:
    queue.tail = high(queue.data)
  else:
    dec queue.tail
  queue.data[queue.tail] = v
  if queue.len < queue.data.len:
    inc queue.len

func pop*[T](queue: var Queue[T]): T =
  result = queue.first
  dec queue.len

func deleteHead*[T](queue: var Queue[T]) =
  dec queue.len

iterator items*[T](queue: Queue[T]): lent T =
  var i = queue.tail
  for _ in 0 ..< queue.len:
    yield queue.data[i]
    i = (i+1) mod queue.data.len

iterator mitems*[T](queue: var Queue[T]): var T =
  var i = queue.tail
  for _ in 0 ..< queue.len:
    yield queue.data[i]
    i = (i+1) mod queue.data.len

func clear*(queue: var Queue) =
  queue.len = 0