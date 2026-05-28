# Arrays

## Creating an array

```shell
fruits=("apple" "banana" "mango")
```
---

## Accessing the elements

```shell
echo "${fruits[0]}" # access the element at index 0 (apple)

echo "${fruits[@]}" # prints all the elements in the array
```
---

## Size of the array

```shell
echo "${#fruits[@]}" 
```
---

## Looping through an array

```shell
for fruit in "${fruits[@]}"; do
    echo "$fruit"
done
```
---

## Adding elements

```shell
fruits+=("orange") # adds the element to the end of the array
fruits+=("kiwi" "mango" "grapes") # adding multiple elements to the end of the array

fruits[2]="orange" # index based insertion
```

### Adding the elements using variables

```shell
new_fruit="pineapple"
fruits+=("$new_fruit")
```

### Appending elements using a loop 

```shell
for item in apple banana orange; do
    fruits+=("$item")
done
```

### Concatenation of arrays

```shell
arr1=("a" "b")
arr2=("c" "d")

arr1+=("${arr2[@]}"

# output : a b c d
```
---

## Removing elements

```shell

unset 'fruits[1]'
fruits+=("new_item")
```
---

# Declare syntax




---

# case
